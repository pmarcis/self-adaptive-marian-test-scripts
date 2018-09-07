#!/bin/bash

MARIAN=/home/marcis/tests/marian-dev/build
MODELDIR=/home/marcis/NMT/en-lv-small-marian/model
DATADIR=/home/marcis/NMT/en-lv-small-marian/en-lv-sa-data-prep
mosesdecoder=/home/marcis/mosesdecoder

WORKDIR=/home/marcis/NMT/en-lv-small-marian/en-lv-sa-experiments
mkdir -p $WORKDIR

for TESTPREFIX in $(ls en-lv-sa-data-prep/*.bpe.context.src | sed -e 's|^en-lv-sa-data-prep/\(.*\).bpe.context.src|\1|'); do

    prefix=$WORKDIR/$TESTPREFIX.baseline
    echo "Running $prefix"

    test -s $prefix.bleu || LC_ALL=C.UTF-8 cat $DATADIR/$TESTPREFIX.bpe.src \
        | $MARIAN/marian-decoder -c $MODELDIR/model.npz.decoder.yml --log $prefix.log \
        -w 3000 -d 0 --mini-batch 32 --maxi-batch 10 \
        | tee $prefix.bpe.out \
        | sed 's/\@\@ //g' \
        | perl $mosesdecoder/scripts/recaser/detruecase.perl \
        | perl $mosesdecoder/scripts/tokenizer/detokenizer.perl -l lv \
        | tee $prefix.out \
        | sacrebleu -l en-lv $DATADIR/$TESTPREFIX.trg \
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
                        | $MARIAN/marian-self-adapt -c $MODELDIR/model.npz.decoder.yml -t $DATADIR/$TESTPREFIX.bpe.context.{src,trg} \
                        -w 3000 -d 0 \
                        --after-batches $U --after-epochs 1 --learn-rate $L --mini-batch $B --log $prefix.log \
                        | tee $prefix.bpe.out \
                        | sed 's/\@\@ //g' \
                        | perl $mosesdecoder/scripts/recaser/detruecase.perl \
                        | perl $mosesdecoder/scripts/tokenizer/detokenizer.perl -l lv \
                        | tee $prefix.out \
                        | sacrebleu $DATADIR/$TESTPREFIX.trg \
                        > $prefix.bleu
                done
            done
        done
    done
done
