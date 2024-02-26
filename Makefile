clean:
	rm -rf public/

serve:
	make clean
	hugo serve --disableFastRender --buildDrafts

post:
	hugo new content posts/$(title)/index.md
