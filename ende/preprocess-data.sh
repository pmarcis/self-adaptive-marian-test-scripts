#!/bin/bash

TOOLS=../tools
MODELDIR=model.wmt2018
WORKDIR=data.wmt2018

rm -rf $WORKDIR
mkdir -p $WORKDIR

for TESTPREFIX in $(ls data/*.json | sed -e 's|^..../\(.*\).json|\1|'); do
    prefixIn=data/$TESTPREFIX
    prefixOut=$WORKDIR/$TESTPREFIX

    echo "Preprocessing $prefixIn"

    cp $prefixIn.src $prefixOut.src
    cp $prefixIn.trg $prefixOut.trg

    for SUFFIX in src context.src; do
        LC_ALL=C.UTF-8 cat $prefixIn.$SUFFIX \
            | $TOOLS/moses-scripts/scripts/tokenizer/tokenizer.perl -a -l en \
            | $TOOLS/moses-scripts/scripts/recaser/truecase.perl -model $MODELDIR/tc.en \
            | $TOOLS/subword-nmt/subword_nmt/apply_bpe.py -c $MODELDIR/ende.bpe \
            > $prefixOut.bpe.$SUFFIX
    done

    for SUFFIX in context.trg; do
        LC_ALL=C.UTF-8 cat $prefixIn.$SUFFIX \
            | $TOOLS/moses-scripts/scripts/tokenizer/tokenizer.perl -a -l en \
            | $TOOLS/moses-scripts/scripts/recaser/truecase.perl -model $MODELDIR/tc.de \
            | $TOOLS/subword-nmt/subword_nmt/apply_bpe.py -c $MODELDIR/ende.bpe \
            > $prefixOut.bpe.$SUFFIX
    done
done
