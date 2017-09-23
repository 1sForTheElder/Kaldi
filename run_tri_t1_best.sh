#!/bin/bash
for x in train_words test_words; do
  steps/make_mfcc.sh data/$x exp/make_mfcc/$x mfcc
  steps/compute_cmvn_stats.sh data/$x exp/make_mfcc/$x mfcc
done
START=$(date +%s);
steps/align_si.sh data/train_words data/lang_wsj exp/word/mono exp/word/mono_ali
steps/train_deltas.sh 1650 15000 data/train_words/ data/lang_wsj exp/word/mono_ali/ exp/word/tri
utils/mkgraph.sh data/lang_wsj_test_bg exp/word/tri exp/word/tri/graph
steps/decode_si.sh --nj 4 exp/word/tri/graph data/test_words exp/word/tri/decode_test
END=$(date +%s);
local/score_words.sh data/test_words exp/word/tri/graph exp/word/tri/decode_test
command>>Q2_best.txt more exp/word/tri/decode_test/scoring_kaldi/best_wer
echo $((END-START))>>Q2_best.txt
echo "best_tri">>Q2_best.txt
echo   >>Q2_best.txt
