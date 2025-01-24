clean:
	rm -rf public/

serve:
	hugo serve --disableFastRender --buildDrafts --gc --minify --bind="0.0.0.0"

# make post title="目录1/..2/标题"
post:
	@hugo new content posts/$(title)/index.md

deploy:
	@git add .
	@git commit -m "$(msg)"
	@git push

featured:
	@wget $(url) -O content/posts/$(title)/featured-image.png

submodule:
	@git submodule update --init --recursive
	@git submodule update --recursive --remote

gh-pages:
	@hugo --gc --minify
	@git subtree push --prefix=public origin gh-pages