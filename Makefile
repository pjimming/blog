clean:
	rm -rf public/

serve:
	make clean
	hugo serve --disableFastRender --buildDrafts --gc

post:
	hugo new content posts/$(title)/index.md
