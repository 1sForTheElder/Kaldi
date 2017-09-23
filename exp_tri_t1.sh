#!/bin/bash

for x in train_words test_words; do
  steps/make_mfcc.sh data/$x exp/make_mfcc/$x mfcc
  steps/compute_cmvn_stats.sh data/$x exp/make_mfcc/$x mfcc
done
echo   >>Q2_task_output.txt
echo "for numleaves">>Q2_task_output.txt
echo   >>Q2_task_output.txt

############# for locating the range of value that gives the lowest WER
for((i=1;i<16;i++))
do
 START=$(date +%s);
 let numleave=$i*500
 pathh="tri_Q2_num_"
 steps/align_si.sh data/train_words data/lang_wsj exp/word/mono exp/word/mono_ali
 steps/train_deltas.sh $numleave 15000 data/train_words/ data/lang_wsj exp/word/mono_ali/ exp/word/$pathh
 utils/mkgraph.sh data/lang_wsj_test_bg exp/word/$pathh exp/word/$pathh/graph
 steps/decode_si.sh --nj 4 exp/word/$pathh/graph data/test_words exp/word/$pathh/decode_test
 END=$(date +%s);
 local/score_words.sh data/test_words exp/word/$pathh/graph exp/word/$pathh/decode_test
 command>>Q2_task_output.txt more exp/word/$pathh/decode_test/scoring_kaldi/best_wer
 echo $((END-START))>>Q2_task_output.txt
 echo $pathh>>Q2_task_output.txt
 echo   >>Q2_task_output.txt

done
############## for specific changes ################
# for((i=-5;i<6;i++))
# do
#  START=$(date +%s);
#  let numleave=1500+$i*50
#  pathh="tri_Q2_num_"
#  steps/align_si.sh data/train_words data/lang_wsj exp/word/mono exp/word/mono_ali
#  steps/train_deltas.sh $numleave 15000 data/train_words/ data/lang_wsj exp/word/mono_ali/ exp/word/$pathh
#  utils/mkgraph.sh data/lang_wsj_test_bg exp/word/$pathh exp/word/$pathh/graph
#  steps/decode_si.sh --nj 4 exp/word/$pathh/graph data/test_words exp/word/$pathh/decode_test
#  END=$(date +%s);
#  local/score_words.sh data/test_words exp/word/$pathh/graph exp/word/$pathh/decode_test
#  command>>Q2_task_output.txt more exp/word/$pathh/decode_test/scoring_kaldi/best_wer
#  echo $((END-START))>>Q2_task_output.txt
#  echo $pathh>>Q2_task_output.txt
#  echo   >>Q2_task_output.txt
#
# done
#
echo   >>Q2_task_output.txt
echo "for totgauss">>Q2_task_output.txt
echo   >>Q2_task_output.txt

################## explore optimal value of totgauss ############################
for((i=1;i<16;i++))
do
 START=$(date +%s);
 let totgau=$i*2500
 pathh="tri_Q2_totgau_"
 steps/align_si.sh data/train_words data/lang_wsj exp/word/mono exp/word/mono_ali
 steps/train_deltas.sh 1500 $totgau data/train_words/ data/lang_wsj exp/word/mono_ali/ exp/word/$pathh
 utils/mkgraph.sh data/lang_wsj_test_bg exp/word/$pathh exp/word/$pathh/graph
 steps/decode.sh --nj 4 exp/word/$pathh/graph data/test_words exp/word/$pathh/decode_test
 END=$(date +%s);
 local/score_words.sh data/test_words exp/word/$pathh/graph exp/word/$pathh/decode_test
 command>>Q2_task_output.txt more exp/word/$pathh/decode_test/scoring_kaldi/best_wer
 echo $((END-START))>>Q2_task_output.txt
 echo $pathh${i}>>Q2_task_output.txt
 echo   >>Q2_task_output.txt
done

################## explore optimal value of totgauss in a smaller range ##########################

# for((i=-4;i<5;i++))
# do
#  START=$(date +%s);
#  let totgau=$i*500+15000
#  pathh="tri_Q2_totgau_"
#  steps/align_si.sh data/train_words data/lang_wsj exp/word/mono exp/word/mono_ali
#  steps/train_deltas.sh 1500 $totgau data/train_words/ data/lang_wsj exp/word/mono_ali/ exp/word/$pathh
#  utils/mkgraph.sh data/lang_wsj_test_bg exp/word/$pathh exp/word/$pathh/graph
#  steps/decode.sh --nj 4 exp/word/$pathh/graph data/test_words exp/word/$pathh/decode_test
#  END=$(date +%s);
#  local/score_words.sh data/test_words exp/word/$pathh/graph exp/word/$pathh/decode_test
#  command>>Q2_task_output.txt more exp/word/$pathh/decode_test/scoring_kaldi/best_wer
#  echo $((END-START))>>Q2_task_output.txt
#  echo $pathh${i}>>Q2_task_output.txt
#  echo   >>Q2_task_output.txt
# done
exit 0
