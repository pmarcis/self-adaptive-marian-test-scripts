#!/bin/bash

MARIAN=/fs/zisa0/romang/marian/marian-dev/build-selfadapt
MODELDIR=model.wmt2018
DATADIR=data.wmt2018

WORKDIR=exp.wmt2018.1
mkdir -p $WORKDIR

for TESTPREFIX in $(ls data/*.json | sed -e 's|^..../\(.*\).json|\1|'); do

    prefix=$WORKDIR/$TESTPREFIX.baseline
    echo "Running $prefix"

    test -s $prefix.bleu || LC_ALL=C.UTF-8 cat $DATADIR/$TESTPREFIX.bpe.src \
        | $MARIAN/marian-decoder -c $MODELDIR/decode.ens1.yml --log $prefix.log \
        -w 3000 -d 0 1 --mini-batch 32 --maxi-batch 10 \
        | tee $prefix.bpe.out \
        | sed 's/\@\@ //g' \
        | ../tools/moses-scripts/scripts/recaser/detruecase.perl \
        | ../tools/moses-scripts/scripts/tokenizer/detokenizer.perl -l de \
        | tee $prefix.out \
        | ../tools/sacreBLEU/sacrebleu.py $DATADIR/$TESTPREFIX.trg \
        > $prefix.bleu

    # --after-batches
    for U in 1 10; do
        # --after epochs
        for E in 1; do
            # --learn-rate
            for L in 0.1 0.001; do
                # --mini-batch
                for B in 1; do

                    prefix=$WORKDIR/$TESTPREFIX.u${U}.e{$E}.b${B}.l${L}
                    echo "Running $prefix"

                    test -s $prefix.bleu || LC_ALL=C.UTF-8 cat $DATADIR/$TESTPREFIX.bpe.src \
                        | $MARIAN/marian-self-adapt -c $MODELDIR/decode.ens1.yml -t $DATADIR/$TESTPREFIX.bpe.context.{src,trg} \
                        -w 3000 -d 0 1 --mini-batch 1 \
                        --after-batches $U --after-epochs 1 --learn-rate $L --mini-batch 1 --log $prefix.log \
                        | tee $prefix.bpe.out \
                        | sed 's/\@\@ //g' \
                        | ../tools/moses-scripts/scripts/recaser/detruecase.perl \
                        | ../tools/moses-scripts/scripts/tokenizer/detokenizer.perl -l de \
                        | tee $prefix.out \
                        | ../tools/sacreBLEU/sacrebleu.py $DATADIR/$TESTPREFIX.trg \
                        > $prefix.bleu
                done
            done
        done
    done
done
