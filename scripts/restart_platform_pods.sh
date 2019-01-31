#!/bin/sh

FB_APPLICATION='fb-publisher' FB_NAMESPACE=publisher FB_DEPLOYMENT_ENV=none node_modules/\@ministryofjustice/fb-deploy-utils/bin/restart_platform_pods.sh $@
