# #!/bin/bash

for x in train_words test_words; do
  steps/make_mfcc.sh data/$x exp/make_mfcc/$x mfcc
  steps/compute_cmvn_stats.sh data/$x exp/make_mfcc/$x mfcc
done
############ train_2_order_delta_model ##################
START=$(date +%s);
steps/align_si.sh data/train_words data/lang_wsj exp/word/mono exp/word/mono_ali
steps/train_deltas.sh 1650 15000 data/train_words/ data/lang_wsj exp/word/mono_ali/ exp/word/tri_delta/
utils/mkgraph.sh data/lang_wsj_test_bg exp/word/tri_delta exp/word/tri_delta/graph
steps/decode_si.sh --nj 4 exp/word/tri_delta/graph data/test_words exp/word/tri_delta/decode_test
local/score_words.sh data/test_words exp/word/tri_delta/graph exp/word/tri_delta/decode_test
END=$(date +%s);
echo "2_order_delta">>Q3_task_2_sat_and_map.txt
command>>Q3_task_2_sat_and_map.txt more exp/word/tri_delta/decode_test/scoring_kaldi/best_wer
echo $((END-START))>>Q3_task_2_sat_and_map.txt
echo   >>Q3_task_2_sat_and_map.txt

########### train_deltas+sat_model #########################
START=$(date +%s);
steps/align_fmllr.sh data/train_words data/lang_wsj exp/word/mono exp/word/mono_ali
steps/train_deltas.sh 1650 15000 data/train_words/ data/lang_wsj exp/word/mono_ali/ exp/word/tri_sat/
steps/train_sat.sh 1650 15000 data/train_words/ data/lang_wsj exp/word/mono_ali/ exp/word/tri_sat/
utils/mkgraph.sh data/lang_wsj_test_bg exp/word/tri_sat exp/word/tri_sat/graph
steps/decode_fmllr.sh --nj 4 exp/word/tri_sat/graph data/test_words exp/word/tri_sat/decode_test
local/score_words.sh data/test_words exp/word/tri_sat/graph exp/word/tri_sat/decode_test
END=$(date +%s);
echo "delta_sat">>Q3_task_2_sat_and_map.txt
command>>Q3_task_2_sat_and_map.txt more exp/word/tri_sat/decode_test/scoring_kaldi/best_wer
echo $((END-START))>>Q3_task_2_sat_and_map.txt
echo   >>Q3_task_2_sat_and_map.txt

########### train_deltas+map_model #########################

START=$(date +%s);
steps/align_si.sh data/train_words data/lang_wsj exp/word/mono exp/word/mono_ali
steps/train_deltas.sh 1650 15000 data/train_words/ data/lang_wsj exp/word/mono_ali/ exp/word/tri_map/
steps/train_map.sh data/train_words/ data/lang_wsj exp/word/mono_ali/ exp/word/tri_map/
utils/mkgraph.sh data/lang_wsj_test_bg exp/word/tri_map exp/word/tri_map/graph
steps/decode_with_map.sh --nj 4 exp/word/tri_map/graph data/test_words exp/word/tri_map/decode_test
local/score_words.sh data/test_words exp/word/tri_map/graph exp/word/tri_map/decode_test
END=$(date +%s);
echo "map_delta">>Q3_task_2_sat_and_map.txt
command>>Q3_task_2_sat_and_map.txt more exp/word/tri_map/decode_test/scoring_kaldi/best_wer
echo $((END-START))>>Q3_task_2_sat_and_map.txt
echo   >>Q3_task_2_sat_and_map.txt

# START=$(date +%s);
# steps/align_si.sh data/train_words data/lang_wsj exp/word/mono exp/word/mono_ali
# steps/train_deltas.sh 1650 15000 data/train_words/ data/lang_wsj exp/word/mono_ali/ exp/word/tri_map/
# steps/train_map.sh data/train_words/ data/lang_wsj exp/word/mono_ali/ exp/word/tri_map/
# utils/mkgraph.sh data/lang_wsj_test_bg exp/word/tri_map exp/word/tri_map/graph
# steps/decode_si.sh --nj 4 exp/word/tri_map/graph data/test_words exp/word/tri_map/decode_test
# local/score_words.sh data/test_words exp/word/tri_map/graph exp/word/tri_map/decode_test
# END=$(date +%s);
# echo "map_delta">>Q3_task_2_sat_and_map.txt
# command>>Q3_task_2_sat_and_map.txt more exp/word/tri_map/decode_test/scoring_kaldi/best_wer
# echo $((END-START))>>Q3_task_2_sat_and_map.txt
# echo   >>Q3_task_2_sat_and_map.txt

exit 0
