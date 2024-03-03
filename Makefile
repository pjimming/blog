clean:
	rm -rf public/

serve:
	hugo serve --disableFastRender --buildDrafts --gc --minify --bind="0.0.0.0"

post:
	@hugo new content posts/$(title)/index.md

deploy:
	@git add .
	@git commit -m "$(msg)"
	@git push

featured:
	@wget $(url) -O content/posts/$(title)/featured-image.png