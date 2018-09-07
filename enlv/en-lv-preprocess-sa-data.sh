#!/bin/bash

mosesdecoder=/home/marcis/mosesdecoder
MODELDIR=/home/marcis/NMT/en-lv-small-marian/model
WORKDIR=/home/marcis/NMT/en-lv-small-marian/en-lv-sa-data-prep
# path to subword segmentation scripts: https://github.com/rsennrich/subword-nmt
subword_nmt=/home/marcis/subword-nmt

rm -rf $WORKDIR
mkdir -p $WORKDIR

for TESTPREFIX in $(ls en-lv-sa-data/*.json | sed -e 's|^en-lv-sa-data/\(.*\).json|\1|'); do
    prefixIn=/home/marcis/NMT/en-lv-small-marian/en-lv-sa-data/$TESTPREFIX
    prefixOut=$WORKDIR/$TESTPREFIX

    echo "Preprocessing $prefixIn"

    cp $prefixIn.src $prefixOut.src
    cp $prefixIn.trg $prefixOut.trg

    for SUFFIX in src context.src; do
        LC_ALL=C.UTF-8 cat $prefixIn.$SUFFIX \
            | $mosesdecoder/scripts/tokenizer/normalize-punctuation.perl -l en \
            | $mosesdecoder/scripts/tokenizer/tokenizer.perl -a -l en \
            | $mosesdecoder/scripts/recaser/truecase.perl -model $MODELDIR/tc.en \
            | $subword_nmt/apply_bpe.py -c $MODELDIR/enlv.bpe \
            > $prefixOut.bpe.$SUFFIX
    done

    for SUFFIX in context.trg; do
        LC_ALL=C.UTF-8 cat $prefixIn.$SUFFIX \
            | $mosesdecoder/scripts/tokenizer/normalize-punctuation.perl -l lv \
            | $mosesdecoder/scripts/tokenizer/tokenizer.perl -a -l lv \
            | $mosesdecoder/scripts/recaser/truecase.perl -model $MODELDIR/tc.lv \
            | $subword_nmt/apply_bpe.py -c $MODELDIR/enlv.bpe \
            > $prefixOut.bpe.$SUFFIX
    done
done
