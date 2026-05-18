.PHONY: all clean

all: venv
	chmod +x submission

venv: requirements.txt
	python3 -m venv venv
	./venv/bin/pip install -r requirements.txt
	touch venv

clean:
	rm -f qrcode.png .totp_secret
	rm -rf venv
