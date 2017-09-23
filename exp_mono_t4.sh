#!/bin/bash

for x in train_words test_words; do
  steps/make_mfcc.sh data/$x exp/make_mfcc/$x mfcc
  steps/compute_cmvn_stats.sh data/$x exp/make_mfcc/$x mfcc
done
for((i=1;i<4;i++))
do
  echo $i
  START=$(date +%s);
  if [[ $i -eq 1 ]]; then
    m_judge=true
    v_judge=false
    use1='_use_means'
    use2='_not_use_variance'
    #statements
  fi
  if [[ $i -eq 2 ]]; then
    m_judge=true
    v_judge=true
    use1='_use_means'
    use2='_use_variance'
    #statements
  fi
  if [[ $i -eq 3 ]]; then
    m_judge=false
    v_judge=true
    use1='_not_use_means'
    use2='_use_variance'
    #statements
  fi
  nj=4
  cmd=run.pl
  scale_opts="--transition-scale=1.0 --acoustic-scale=0.1 --self-loop-scale=0.1"
  num_iters=40   # Number of iterations of training
  max_iter_inc=30 # Last iter to increase #Gauss on.
  totgauss=6340 # Target #Gaussians.
  careful=false
  boost_silence=1.0 # Factor by which to boost silence likelihoods in alignment
  realign_iters="1 2 3 4 5 6 7 8 9 10 12 14 16 18 20 23 26 29 32 35 38";
  config= # name of config file.
  stage=-4
  delta_opts="--delta-order=2"
  power=0.25 # exponent to determine number of gaussians from occurrence counts
  norm_vars=false # deprecated, prefer --cmvn-opts "--norm-vars=false"
  cmvn_opts=  # can be used to add extra options to cmvn.
  # End configuration section.

  data="data/train_words"
  lang="data/lang_wsj"
  dir="exp/mono_"${use1}${use2}

  oov_sym=`cat $lang/oov.int` || exit 1;

  mkdir -p $dir/log
  echo $nj > $dir/num_jobs
  sdata=$data/split$nj;

  [[ -d $sdata && $data/feats.scp -ot $sdata ]] || split_data.sh $data $nj || exit 1;

  cp $lang/phones.txt $dir || exit 1;

  $norm_vars && cmvn_opts="--norm-vars=true $cmvn_opts"
  feats="ark,s,cs:apply-cmvn --norm-means=$m_judge --norm-vars=$v_judge --utt2spk=ark:$sdata/JOB/utt2spk scp:$sdata/JOB/cmvn.scp scp:$sdata/JOB/feats.scp ark:- | add-deltas ark:- ark:- |"
  example_feats="`echo $feats | sed s/JOB/1/g`";

  echo "$0: Initializing monophone system."

  [ ! -f $lang/phones/sets.int ] && exit 1;
  shared_phones_opt="--shared-phones=$lang/phones/sets.int"

  if [ $stage -le -3 ]; then
    # Note: JOB=1 just uses the 1st part of the features-- we only need a subset anyway.
    if ! feat_dim=`feat-to-dim "$example_feats" - 2>/dev/null` || [ -z $feat_dim ]; then
      feat-to-dim "$example_feats" -
      echo "error getting feature dimension"
      exit 1;
    fi
    $cmd JOB=1 $dir/log/init.log \
      gmm-init-mono $shared_phones_opt "--train-feats=$feats subset-feats --n=10 ark:- ark:-|" $lang/topo $feat_dim \
      $dir/0.mdl $dir/tree || exit 1;
  fi

  numgauss=`gmm-info --print-args=false $dir/0.mdl | grep gaussians | awk '{print $NF}'`
  incgauss=$[($totgauss-$numgauss)/$max_iter_inc] # per-iter increment for #Gauss

  if [ $stage -le -2 ]; then
    echo "$0: Compiling training graphs"
    $cmd JOB=1:$nj $dir/log/compile_graphs.JOB.log \
      compile-train-graphs --read-disambig-syms=$lang/phones/disambig.int $dir/tree $dir/0.mdl  $lang/L.fst \
      "ark:sym2int.pl --map-oov $oov_sym -f 2- $lang/words.txt < $sdata/JOB/text|" \
      "ark:|gzip -c >$dir/fsts.JOB.gz" || exit 1;
  fi

  if [ $stage -le -1 ]; then
    echo "$0: Aligning data equally (pass 0)"
    $cmd JOB=1:$nj $dir/log/align.0.JOB.log \
      align-equal-compiled "ark:gunzip -c $dir/fsts.JOB.gz|" "$feats" ark,t:-  \| \
      gmm-acc-stats-ali --binary=true $dir/0.mdl "$feats" ark:- \
      $dir/0.JOB.acc || exit 1;
  fi

  # In the following steps, the --min-gaussian-occupancy=3 option is important, otherwise
  # we fail to est "rare" phones and later on, they never align properly.

  if [ $stage -le 0 ]; then
    gmm-est --min-gaussian-occupancy=3  --mix-up=$numgauss --power=$power \
      $dir/0.mdl "gmm-sum-accs - $dir/0.*.acc|" $dir/1.mdl 2> $dir/log/update.0.log || exit 1;
    rm $dir/0.*.acc
  fi


  beam=6 # will change to 10 below after 1st pass
  # note: using slightly wider beams for WSJ vs. RM.
  x=1
  while [ $x -lt $num_iters ]; do
    echo "$0: Pass $x"
    if [ $stage -le $x ]; then
      if echo $realign_iters | grep -w $x >/dev/null; then
        echo "$0: Aligning data"
        mdl="gmm-boost-silence --boost=$boost_silence `cat $lang/phones/optional_silence.csl` $dir/$x.mdl - |"
        $cmd JOB=1:$nj $dir/log/align.$x.JOB.log \
          gmm-align-compiled $scale_opts --beam=$beam --retry-beam=$[$beam*4] --careful=$careful "$mdl" \
          "ark:gunzip -c $dir/fsts.JOB.gz|" "$feats" "ark,t:|gzip -c >$dir/ali.JOB.gz" \
          || exit 1;
      fi
      $cmd JOB=1:$nj $dir/log/acc.$x.JOB.log \
        gmm-acc-stats-ali  $dir/$x.mdl "$feats" "ark:gunzip -c $dir/ali.JOB.gz|" \
        $dir/$x.JOB.acc || exit 1;

      $cmd $dir/log/update.$x.log \
        gmm-est --write-occs=$dir/$[$x+1].occs --mix-up=$numgauss --power=$power $dir/$x.mdl \
        "gmm-sum-accs - $dir/$x.*.acc|" $dir/$[$x+1].mdl || exit 1;
      rm $dir/$x.mdl $dir/$x.*.acc $dir/$x.occs 2>/dev/null
    fi
    if [ $x -le $max_iter_inc ]; then
       numgauss=$[$numgauss+$incgauss];
    fi
    beam=10
    x=$[$x+1]
  done

  ( cd $dir; rm final.{mdl,occs} 2>/dev/null; ln -s $x.mdl final.mdl; ln -s $x.occs final.occs )


  steps/diagnostic/analyze_alignments.sh --cmd "$cmd" $lang $dir
  utils/summarize_warnings.pl $dir/log

  steps/info/gmm_dir_info.pl $dir

  echo "$0: Done training monophone system in $dir"
  utils/mkgraph.sh --mono data/lang_wsj_test_bg $dir $dir/graph;

  dir1=$dir






  transform_dir=   # this option won't normally be used, but it can be used if you want to
                   # supply existing fMLLR transforms when decoding.
  iter=
  delta_opts1="--delta-order=2"
  model= # You can specify the model to use (e.g. if you want to use the .alimdl)
  stage=0
  nj=4
  cmd=run.pl
  max_active=7000
  beam=13.0
  lattice_beam=6.0
  acwt=0.083333 # note: only really affects pruning (scoring is on lattices).
  num_threads=4 # if >1, will use gmm-latgen-faster-parallel
  parallel_opts=  # ignored now.
  scoring_opts=
  # note: there are no more min-lmwt and max-lmwt options, instead use
  # e.g. --scoring-opts "--min-lmwt 1 --max-lmwt 20"
  skip_scoring=false
  # End configuration section.

  graphdir="$dir1/graph"
  data="data/test_words"
  dir="$dir1/decode_test"
  srcdir=`dirname $dir`; # The model directory is one level up from decoding directory.
  sdata=$data/split$nj;

  mkdir -p $dir/log
  [[ -d $sdata && $data/feats.scp -ot $sdata ]] || split_data.sh $data $nj || exit 1;
  echo $nj > $dir/num_jobs

  if [ -z "$model" ]; then # if --model <mdl> was not specified on the command line...
    if [ -z $iter ]; then model=$srcdir/final.mdl;
    else model=$srcdir/$iter.mdl; fi
  fi

  if [ $(basename $model) != final.alimdl ] ; then
    # Do not use the $srcpath -- look at the path where the model is
    if [ -f $(dirname $model)/final.alimdl ] && [ -z "$transform_dir" ]; then
      echo -e '\n\n'
      echo $0 'WARNING: Running speaker independent system decoding using a SAT model!'
      echo $0 'WARNING: This is OK if you know what you are doing...'
      echo -e '\n\n'
    fi
  fi

  for f in $sdata/1/feats.scp $sdata/1/cmvn.scp $model $graphdir/HCLG.fst; do
    [ ! -f $f ] && echo "decode.sh: no such file $f" && exit 1;
  done

  if [ -f $srcdir/final.mat ]; then feat_type=lda; else feat_type=delta; fi
  echo "decode.sh: feature type is $feat_type";

  splice_opts=`cat $srcdir/splice_opts 2>/dev/null` # frame-splicing options.
  cmvn_opts=`cat $srcdir/cmvn_opts 2>/dev/null`
  delta_opts=`cat $srcdir/delta_opts 2>/dev/null`

  thread_string=
  [ $num_threads -gt 1 ] && thread_string="-parallel --num-threads=$num_threads"

  case $feat_type in
    delta) feats="ark,s,cs:apply-cmvn --norm-means=$m_judge --norm-vars=$v_judge --utt2spk=ark:$sdata/JOB/utt2spk scp:$sdata/JOB/cmvn.scp scp:$sdata/JOB/feats.scp ark:- | add-deltas ark:- ark:- |";;
    lda) feats="ark,s,cs:apply-cmvn --norm-means=$m_judge --norm-vars=$v_judge --utt2spk=ark:$sdata/JOB/utt2spk scp:$sdata/JOB/cmvn.scp scp:$sdata/JOB/feats.scp ark:- | splice-feats $splice_opts ark:- ark:- | transform-feats $srcdir/final.mat ark:- ark:- |";;
    *) echo "Invalid feature type $feat_type" && exit 1;
  esac

  if [ ! -z "$transform_dir" ]; then # add transforms to features...
    echo "Using fMLLR transforms from $transform_dir"
    [ ! -f $transform_dir/trans.1 ] && echo "Expected $transform_dir/trans.1 to exist."
    [ ! -s $transform_dir/num_jobs ] && \
      echo "$0: expected $transform_dir/num_jobs to contain the number of jobs." && exit 1;
    nj_orig=$(cat $transform_dir/num_jobs)
    if [ $nj -ne $nj_orig ]; then
      # Copy the transforms into an archive with an index.
      echo "$0: num-jobs for transforms mismatches, so copying them."
      for n in $(seq $nj_orig); do cat $transform_dir/trans.$n; done | \
         copy-feats ark:- ark,scp:$dir/trans.ark,$dir/trans.scp || exit 1;
      feats="$feats transform-feats --utt2spk=ark:$sdata/JOB/utt2spk scp:$dir/trans.scp ark:- ark:- |"
    else
      # number of jobs matches with alignment dir.
      feats="$feats transform-feats --utt2spk=ark:$sdata/JOB/utt2spk ark:$transform_dir/trans.JOB ark:- ark:- |"
    fi
  fi

  if [ $stage -le 0 ]; then
    if [ -f "$graphdir/num_pdfs" ]; then
      [ "`cat $graphdir/num_pdfs`" -eq `am-info --print-args=false $model | grep pdfs | awk '{print $NF}'` ] || \
        { echo "Mismatch in number of pdfs with $model"; exit 1; }
    fi

    $cmd --num-threads $num_threads JOB=1:$nj $dir/log/decode.JOB.log \
      gmm-latgen-faster$thread_string --max-active=$max_active --beam=$beam --lattice-beam=5.0 \
      --acoustic-scale=$acwt --allow-partial=true --word-symbol-table=$graphdir/words.txt \
      $model $graphdir/HCLG.fst "$feats" "ark:|gzip -c > $dir/lat.JOB.gz" || exit 1;
  fi

  if ! $skip_scoring ; then
    [ ! -x local/score.sh ] && \
      echo "Not scoring because local/score.sh does not exist or not executable." && exit 1;
    local/score.sh --cmd "$cmd" $scoring_opts $data $graphdir $dir ||
      { echo "$0: Scoring failed. (ignore by '--skip-scoring true')"; exit 1; }
  fi
  echo $dir
  dir=$dir1
  END=$(date +%s);
  local/score_words.sh data/test_words $dir/graph $dir/decode_test
  echo "mono_"${use1}${use2}>>Q1_task_4.txt;
  echo $((END-START))>>Q1_task_4.txt
  command>>Q1_task_4.txt more $dir/decode_test/scoring_kaldi/best_wer
  echo    >>Q1_task_4.txt
  echo "finish one time"

done
exit 0
