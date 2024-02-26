serve:
	hugo serve --disableFastRender

post:
	hugo new content posts/$(title).md
