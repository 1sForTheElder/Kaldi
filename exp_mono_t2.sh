#!/bin/bash

for x in train_words test_words; do
  steps/make_plp.sh data/$x exp/make_plp/$x plp
  steps/compute_cmvn_stats.sh data/$x exp/make_plp/$x plp
done
START=$(date +%s);
steps/align_si.sh data/train_words data/lang_wsj exp/word/mono exp/word/mono_ali
steps/train_mono.sh --nj 4 --totgauss 6340 data/train_words data/lang_wsj exp/monoPLP;
utils/mkgraph.sh --mono data/lang_wsj_test_bg exp/monoPLP exp/monoPLP/graph;
steps/decode.sh --nj 4 exp/monoPLP/graph data/test_words exp/monoPLP/decode_test;
END=$(date +%s);
local/score_words.sh data/test_words exp/monoPLP/graph exp/monoPLP/decode_test
echo "the plp">>Q1_task_2.txt;
command>>Q1_task_2.txt more exp/monoPLP/decode_test/scoring_kaldi/best_wer
echo $((END-START))>>Q1_task_2.txt
echo    >>Q1_task_2.txt

#
for x in train_words test_words; do
  steps/make_fbank.sh data/$x data/make_fbank/$x fbank
  steps/compute_cmvn_stats.sh data/$x data/make_fbank/$x fbank
done
START=$(date +%s);
steps/align_si.sh data/train_words data/lang_wsj exp/word/mono exp/word/mono_ali
steps/train_mono.sh --nj 4 --totgauss 6340 data/train_words data/lang_wsj exp/monoFbank;
utils/mkgraph.sh --mono data/lang_wsj_test_bg exp/monoFbank exp/monoFbank/graph;
steps/decode.sh --nj 4 exp/monoFbank/graph data/test_words exp/monoFbank/decode_test;
END=$(date +%s);
local/score_words.sh data/test_words exp/monoFbank/graph exp/monoFbank/decode_test
echo "the fbank">>Q1_task_2.txt;
command>>Q1_task_2.txt more exp/monoFbank/decode_test/scoring_kaldi/best_wer
echo $((END-START))>>Q1_task_2.txt
echo    >>Q1_task_2.txt
