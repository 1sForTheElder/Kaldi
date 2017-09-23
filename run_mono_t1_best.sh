#!/bin/bash
START=$(date +%s);
steps/train_mono.sh --nj 4 --totgauss 6336 data/train_words data/lang_wsj exp/word/mono_best;
utils/mkgraph.sh --mono data/lang_wsj_test_bg exp/word/mono_best exp/word/mono_best/graph
steps/decode.sh --nj 4 exp/word/mono_best/graph data/test_words exp/word/mono_best/decode_test;
local/score_words.sh data/test_words exp/word/mono_best/graph exp/word/mono_best/decode_test
END=$(date +%s);
more exp/word/mono_best/decode_test/scoring_kaldi/best_wer
