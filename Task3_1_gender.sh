#!/bin/bash

for x in train_words_female test_words_female; do
  steps/make_mfcc.sh data/$x exp/make_mfcc/$x mfcc
  steps/compute_cmvn_stats.sh data/$x exp/make_mfcc/$x mfcc
done
for x in train_words_male test_words_male; do
  steps/make_mfcc.sh data/$x exp/make_mfcc/$x mfcc
  steps/compute_cmvn_stats.sh data/$x exp/make_mfcc/$x mfcc
done
START=$(date +%s);
steps/align_si.sh data/train_words_male data/lang_wsj exp/word/mono exp/word/mono_ali
steps/train_deltas.sh 1650 15000 data/train_words_male/ data/lang_wsj exp/word/mono_ali/ exp/word/train_only_male/
utils/mkgraph.sh data/lang_wsj_test_bg exp/word/train_only_male exp/word/train_only_male/graph
steps/decode_si.sh --nj 4 exp/word/train_only_male/graph data/test_words_male exp/word/train_only_male/decode_test
local/score_words.sh data/test_words exp/word/train_only_male/graph exp/word/train_only_male/decode_test
END=$(date +%s);
echo "train_male_decode_male">>Q3_1_gender.txt
command>>Q3_1_gender.txt more exp/word/train_only_male/decode_test/scoring_kaldi/best_wer
echo $((END-START))>>Q3_1_gender.txt
echo   >>Q3_1_gender.txt

for x in train_words test_words; do
  steps/make_mfcc.sh data/$x exp/make_mfcc/$x mfcc
  steps/compute_cmvn_stats.sh data/$x exp/make_mfcc/$x mfcc
done
START=$(date +%s);
steps/align_si.sh data/train_words_male data/lang_wsj exp/word/mono exp/word/mono_ali
steps/train_deltas.sh 1650 15000 data/train_words_male/ data/lang_wsj exp/word/mono_ali/ exp/word/train_male_decode_all/
utils/mkgraph.sh data/lang_wsj_test_bg exp/word/train_male_decode_all exp/word/train_male_decode_all/graph
steps/decode_si.sh --nj 4 exp/word/train_male_decode_all/graph data/test_words exp/word/train_male_decode_all/decode_test
local/score_words.sh data/test_words exp/word/train_male_decode_all/graph exp/word/train_male_decode_all/decode_test
END=$(date +%s);
echo "train_male_decode_all">>Q3_1_gender.txt
command>>Q3_1_gender.txt more exp/word/train_male_decode_all/decode_test/scoring_kaldi/best_wer
echo $((END-START))>>Q3_1_gender.txt
echo   >>Q3_1_gender.txt

START=$(date +%s);
steps/align_si.sh data/train_words_male data/lang_wsj exp/word/mono exp/word/mono_ali
steps/train_deltas.sh 1650 15000 data/train_words_male/ data/lang_wsj exp/word/mono_ali/ exp/word/train_male_decode_female/
utils/mkgraph.sh data/lang_wsj_test_bg exp/word/train_male_decode_female exp/word/train_male_decode_female/graph
steps/decode_si.sh --nj 4 exp/word/train_male_decode_female/graph data/test_words_female exp/word/train_male_decode_female/decode_test
local/score_words.sh data/test_words exp/word/train_male_decode_female/graph exp/word/train_male_decode_female/decode_test
END=$(date +%s);
echo "train_male_decode_female">>Q3_1_gender.txt
command>>Q3_1_gender.txt more exp/word/train_male_decode_female/decode_test/scoring_kaldi/best_wer
echo $((END-START))>>Q3_1_gender.txt
echo   >>Q3_1_gender.txt

for x in train_words_female test_words_female; do
  steps/make_mfcc.sh data/$x exp/make_mfcc/$x mfcc
  steps/compute_cmvn_stats.sh data/$x exp/make_mfcc/$x mfcc
done
steps/align_si.sh data/train_words_female data/lang_wsj exp/word/mono exp/word/mono_ali
steps/train_deltas.sh 1650 15000 data/train_words_female/ data/lang_wsj exp/word/mono_ali/ exp/word/train_only_female/
utils/mkgraph.sh data/lang_wsj_test_bg exp/word/train_only_female exp/word/train_only_female/graph
steps/decode_si.sh --nj 4 exp/word/train_only_female/graph data/test_words_female exp/word/train_only_female/decode_test
local/score_words.sh data/test_words exp/word/train_only_female/graph exp/word/train_only_female/decode_test
END=$(date +%s);
echo "train_female_decode_female">>Q3_1_gender.txt
command>>Q3_1_gender.txt more exp/word/train_only_female/decode_test/scoring_kaldi/best_wer
echo $((END-START))>>Q3_1_gender.txt
echo   >>Q3_1_gender.txt

START=$(date +%s);
steps/align_si.sh data/train_words_female data/lang_wsj exp/word/mono exp/word/mono_ali
steps/train_deltas.sh 1650 15000 data/train_words_female/ data/lang_wsj exp/word/mono_ali/ exp/word/train_female_decode_all/
utils/mkgraph.sh data/lang_wsj_test_bg exp/word/train_female_decode_all exp/word/train_female_decode_all/graph
steps/decode_si.sh --nj 4 exp/word/train_female_decode_all/graph data/test_words exp/word/train_female_decode_all/decode_test
local/score_words.sh data/test_words exp/word/train_female_decode_all/graph exp/word/train_female_decode_all/decode_test
END=$(date +%s);
echo "train_female_decode_all">>Q3_1_gender.txt
command>>Q3_1_gender.txt more exp/word/train_female_decode_all/decode_test/scoring_kaldi/best_wer
echo $((END-START))>>Q3_1_gender.txt
echo   >>Q3_1_gender.txt

START=$(date +%s);
steps/align_si.sh data/train_words_female data/lang_wsj exp/word/mono exp/word/mono_ali
steps/train_deltas.sh 1650 15000 data/train_words_female/ data/lang_wsj exp/word/mono_ali/ exp/word/train_female_decode_male/
utils/mkgraph.sh data/lang_wsj_test_bg exp/word/train_female_decode_male exp/word/train_female_decode_male/graph
steps/decode_si.sh --nj 4 exp/word/train_female_decode_male/graph data/test_words_male exp/word/train_female_decode_male/decode_test
local/score_words.sh data/test_words exp/word/train_female_decode_male/graph exp/word/train_female_decode_male/decode_test
END=$(date +%s);
echo "train_female_decode_male">>Q3_1_gender.txt
command>>Q3_1_gender.txt more exp/word/train_female_decode_male/decode_test/scoring_kaldi/best_wer
echo $((END-START))>>Q3_1_gender.txt
echo   >>Q3_1_gender.txt

exit 0
