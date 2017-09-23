#!/bin/bash
for x in train_words test_words; do
  steps/make_mfcc.sh data/$x exp/make_mfcc/$x mfcc
  steps/compute_cmvn_stats.sh data/$x exp/make_mfcc/$x mfcc
done
o=144;
for((i=1;i<76;i++))
do
  mononame="mono_Q1_task_1"
  START=$(date +%s);
  p=$o*$i;
  steps/align_si.sh data/train_words data/lang_wsj exp/word/mono exp/word/mono_ali
  steps/train_mono.sh --nj 4 --num_iters 40 --totgauss $p data/train_words data/lang_wsj exp/word/$mononame;
  utils/mkgraph.sh --mono data/lang_wsj_test_bg exp/word/$mononame exp/word/$mononame/graph
  steps/decode_si.sh --nj 4 exp/word/$mononame/graph data/test_words exp/word/$mononame/decode_test;
  local/score_words.sh data/test_words exp/word/$mononame/graph exp/word/$mononame/decode_test
  END=$(date +%s);
  echo "the $i time">>Q1_task_1.txt;
  command>>Q1_task_1.txt more exp/word/$mononame/decode_test/scoring_kaldi/best_wer
  echo    >>Q1_task_1.txt
  echo "finish one time"
  echo $((END-START))>>Q1_task_1.txt
  echo    >>Q1_task_1.txt
done
