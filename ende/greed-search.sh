#!/bin/bash

MARIAN=/fs/zisa0/romang/marian/marian-dev/build-selfadapt
MODELDIR=model
DATADIR=data.prep
DEVICES="1"

WORKDIR=output
mkdir -p $WORKDIR

for TESTPREFIX in $(ls data/*.json | sed -e 's|^..../\(.*\).json|\1|'); do

    prefix=$WORKDIR/$TESTPREFIX.baseline
    echo "Running $prefix"

    test -s $prefix.bleu || LC_ALL=C.UTF-8 cat $DATADIR/$TESTPREFIX.bpe.src \
        | $MARIAN/marian-decoder -c $MODELDIR/decode.yml --log $prefix.log \
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

                    prefix=$WORKDIR/$TESTPREFIX.u${U}.e${E}.b${B}.l${L}
                    echo "Running $prefix"

                    test -s $prefix.bleu || LC_ALL=C.UTF-8 cat $DATADIR/$TESTPREFIX.bpe.src \
                        | $MARIAN/marian-self-adapt -c $MODELDIR/selfadapt.yml \
                            -w 3000 -d $DEVICES --mini-batch 1 \
                            -t $DATADIR/$TESTPREFIX.bpe.context.{src,trg} \
                            --after-batches $U --after-epochs 1 --learn-rate $L --log $prefix.log \
                        | tee $prefix.bpe.out \
                        | sed 's/\@\@ //g' \
                        | ../tools/moses-scripts/scripts/recaser/detruecase.perl \
                        | ../tools/moses-scripts/scripts/tokenizer/detokenizer.perl -l de \
                        | tee $prefix.out \
                        | ../tools/sacreBLEU/sacrebleu.py $DATADIR/$TESTPREFIX.trg \
                        > $prefix.bleu

                    echo "Remove this exit!!!"
                    exit 1

                done
            done
        done
    done

done
