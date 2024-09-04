ELASTIC_SEARCH_IMAGE=elasticsearch_cust
KIBANA_IMAGE=kibana
SNOWFLAKE_REPO?=sfseeurope-us-west-ccarrero-452.registry.snowflakecomputing.com/pr_llmdemo/public/images
IMAGE_REGISTRY=sfseeurope-us-west-ccarrero-452.registry.snowflakecomputing.com


help: ## Show this help.
	@fgrep -h "##" $(MAKEFILE_LIST) | fgrep -v fgrep | sed -e 's/\\$$//' | sed -e 's/##//'

all: login build push

login:  ## Login to Snowflake Docker repo. Uses snowcli.
	docker login ${IMAGE_REGISTRY} -u praj 

build: build_elasticsearch build_kibana 

build_elasticsearch: ## Builds elastic search container
	cd elasticsearch && docker build --platform linux/amd64 -t $(ELASTIC_SEARCH_IMAGE) . && cd ..

build_kibana: ## Builds kibana container
	cd kibana && docker build --platform linux/amd64 -t $(KIBANA_IMAGE) . && cd ..

push: push_elasticsearch push_kibana 

push_elasticsearch:
	docker tag $(ELASTIC_SEARCH_IMAGE) ${SNOWFLAKE_REPO}/$(ELASTIC_SEARCH_IMAGE)
	docker push ${SNOWFLAKE_REPO}/$(ELASTIC_SEARCH_IMAGE)

push_kibana:
	docker tag $(KIBANA_IMAGE) ${SNOWFLAKE_REPO}/$(KIBANA_IMAGE)
	docker push ${SNOWFLAKE_REPO}/$(KIBANA_IMAGE)

