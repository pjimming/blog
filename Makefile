clean:
	rm -rf public/

serve:
	hugo serve --disableFastRender --buildDrafts --gc --minify

post:
	hugo new content posts/$(title)/index.md

deploy:
	git add .
	git commit -m "$(msg)"
	git push
