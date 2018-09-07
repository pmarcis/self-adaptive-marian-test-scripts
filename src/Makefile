#LAST := 1000
#NUMBERS := $(shell seq 1 ${LAST})
#JOBS := $(addprefix job,${NUMBERS})
#.PHONY: all ${JOBS}
#all: ${JOBS} ; echo "$@ success"
#${JOBS}: job%: ; ./a.out $*

en-lv.zip:
	wget -O en-lv.zip 'https://onedrive.live.com/download?cid=F23089D3C3E53B34&resid=F23089D3C3E53B34%21107671&authkey=AEifl27S-w2lahM'

model.zip:
	wget -O model.zip 'https://onedrive.live.com/download?cid=F23089D3C3E53B34&resid=F23089D3C3E53B34%21107673&authkey=AJwst_hXx8pIkWY'

model.npz vocab.yml preprocess-data.sh tc-model.en tc-model.lv enlv.bpe: model.zip
	rm -rf en-lv-marian-model
	unzip model.zip
	cp en-lv-marian-model/model/model.npz ./
	cp en-lv-marian-model/train.bpe.enlv.yml ./vocab.yml
	cp en-lv-marian-model/preprocess-data.sh ./
	cp en-lv-marian-model/model/tc.en ./tc-model.en
	cp en-lv-marian-model/model/tc.lv ./tc-model.lv
	cp en-lv-marian-model/model/enlv.bpe ./enlv.bpe

moses-scripts:
	rm -rf moses-scripts
	git clone https://github.com/marian-nmt/moses-scripts.git

subword-nmt:
	git clone https://github.com/rsennrich/subword-nmt.git

#normalize-punctuation.perl: moses-scripts
#	cp moses-scripts/scripts/tokenizer/normalize-punctuation.perl ./
#tokenizer.perl: moses-scripts
#	cp moses-scripts/scripts/tokenizer/tokenizer.perl ./
#truecase.perl: moses-scripts
#	cp moses-scripts/scripts/recaser/truecase.perl ./

TSCRIPTS:= "moses-scripts/scripts/tokenizer/"
RSCRIPTS:= "moses-scripts/scripts/recaser/"


OpenSubtitles2018.en-lv.random.context.src OpenSubtitles2018.en-lv.random.context.trg OpenSubtitles2018.en-lv.random.src OpenSubtitles2018.en-lv.random.trg: en-lv.zip
	rm -rf en-lv-self-adaptive-nmt-eval-set
	unzip en-lv.zip
	cp en-lv-self-adaptive-nmt-eval-set/OpenSubtitles2018.en-lv.random.* ./


define normalize
    ./normalize-punctuation.perl -l $2 < $1 > $1.norm.$2
endef

define preprocess
    cat $1 \
        | ./$(TSCRIPTS)/normalize-punctuation.perl -l $2 \
        | ./$(TSCRIPTS)/tokenizer.perl -a -l $2 > $1.tok.$2
endef

c.tok.en: OpenSubtitles2018.en-lv.random.context.src moses-scripts
	$(call preprocess,OpenSubtitles2018.en-lv.random.context.src,en)
	mv OpenSubtitles2018.en-lv.random.context.src.tok.en c.tok.en
c.tok.lv: OpenSubtitles2018.en-lv.random.context.trg moses-scripts
	$(call preprocess,OpenSubtitles2018.en-lv.random.context.trg,lv)
	mv OpenSubtitles2018.en-lv.random.context.trg.tok.lv c.tok.lv
tok.en: OpenSubtitles2018.en-lv.random.src moses-scripts
	$(call preprocess,OpenSubtitles2018.en-lv.random.src,en)
	mv OpenSubtitles2018.en-lv.random.src.tok.en tok.en
norm.lv: OpenSubtitles2018.en-lv.random.trg moses-scripts
	$(call normalize,OpenSubtitles2018.en-lv.random.trg,lv)
	mv OpenSubtitles2018.en-lv.random.trg.norm.lv norm.lv

tc.en: tc-model.en tok.en moses-scripts
	./$(RSCRIPTS)/truecase.perl -model tc-model.en < tok.en > tc.en
c.tc.en: tc-model.en c.tok.en moses-scripts
	./$(RSCRIPTS)/truecase.perl -model tc-model.en < c.tok.en > c.tc.en
c.tc.lv: tc-model.lv c.tok.lv moses-scripts
	./$(RSCRIPTS)/truecase.perl -model tc-model.lv < c.tok.lv > c.tc.lv

bpe.en: tc.en subword-nmt
	./subword-nmt/apply_bpe.py -c enlv.bpe < tc.en > bpe.en
c.bpe.en: c.tc.en subword-nmt
	./subword-nmt/apply_bpe.py -c enlv.bpe < c.tc.en > c.bpe.en
c.bpe.lv: c.tc.lv subword-nmt
	./subword-nmt/apply_bpe.py -c enlv.bpe < c.tc.lv > c.bpe.lv

data: bpe.en c.bpe.en c.bpe.lv

MARIAN:= "../marian-dev"
ADAPT:= $(MARIAN)/build/marian-self-adapt

L:= 0.001 0.002
E:= 1 2
B:= 1 10
define make-translate-target
	lv-$1-$2-$3: bpe.en c.bpe.en c.bpe.lv model.npz vocab.yml
	  ./$(ADAPT) \
	  -m model.npz \
	  -v vocab.yml \
	  --dim-vocabs 85000 85000 --dim-emb 500 \
	  --learn-rate $1 --after-epochs $2 --mini-batch $3  \
	  -t c.bpe.en c.bpe.lv --log $1-$2-$3.log < bpe.en > lv-$1-$2-$3.out
	all:: 
  all:: lv-$1-$2-$3
endef

#$(foreach element,$(LIST),$(eval $(call make-rambo-target,$(element))))

lv-$1-$2-$3: bpe.en c.bpe.en c.bpe.lv model.npz vocab.yml
	  ./$(ADAPT) \
	  -m model.npz \
	  -v vocab.yml \
	  --dim-vocabs 85000 85000 --dim-emb 500 \
	  --learn-rate $1 --after-epochs $2 --mini-batch $3  \
	  -t c.bpe.en c.bpe.lv --log $1-$2-$3.log < bpe.en > lv-$1-$2-$3.out
	all:: 
