set -e

IMAGE_TAG="$1"

if [ -z "$IMAGE_TAG" ]; then
   echo "no image provided"
   exit 1
fi

REPO="207224908189.dkr.ecr.us-east-1.amazonaws.com"
NEW_IMAGE="$REPO"/flask-app:"$IMAGE_TAG"
PREVIOUS_IMAGE=""
HAS_PREVIOUS=false
if docker container inspect flask-app > /dev/null 2>&1; then
   PREVIOUS_IMAGE=$(docker inspect --format='{{.Config.Image}}' flask-app)
   HAS_PREVIOUS=true
fi


aws ecr get-login-password --region us-east-1 \
  | docker login --username AWS \
    --password-stdin "$REPO"

docker pull "$NEW_IMAGE"

if [ "$HAS_PREVIOUS" = true ]; then
   docker stop flask-app
   docker rm flask-app
fi

docker run -d --name flask-app -p 8000:8000 --restart unless-stopped "$NEW_IMAGE"
HEALTH=false
for i in {1..10}; do
   if curl --fail localhost:8000/health > /dev/null 2>&1; then
      echo "Container is working"
      HEALTH=true
      break
    else
      echo "resending health check"
      sleep 2
    fi
done

if [ "$HEALTH" = false ]; then
   echo "ROLLBACK"
   docker stop flask-app
   docker rm flask-app
    if [ "$HAS_PREVIOUS = true" ]; then
      docker run -d --name flask-app -p 8000:8000 --restart unless-stopped "$PREVIOUS_IMAGE"
    else
      echo "No rollback"
      exit 1
    fi
else
   exit 0
fi 

echo "HEALTH CHECK FOR ROLLBACK"


for i in {1..10}; do
   if curl --fail localhost:8000/health > /dev/null 2>&1; then
      echo "ROLLBACK WORKING"
      exit 1
    else
      echo "RETRY"
      sleep 2
    fi
done

exit 1
   

      