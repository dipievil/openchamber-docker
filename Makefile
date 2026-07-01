.PHONY: build run test clean version

VERSION ?= latest

build:
	docker build --build-arg OPENCHAMBER_VERSION=$(VERSION) \
		-t dipi/openchamber:local -f docker/Dockerfile .

run:
	docker compose up -d

test:
	docker build --build-arg OPENCHAMBER_VERSION=$(VERSION) \
		-t dipi/openchamber:test -f docker/Dockerfile .
	docker run --rm dipi/openchamber:test bun packages/web/bin/cli.js --version

clean:
	docker compose down -v
	docker rmi dipi/openchamber:local 2>/dev/null || true

version:
	@curl -s https://api.github.com/repos/openchamber/openchamber/releases/latest \
		| jq -r .tag_name
