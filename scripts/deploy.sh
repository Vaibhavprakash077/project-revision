#!/bin/bash

set -e

NEW_IMAGE_TAG="$1"

if [ -z "$NEW_IMAGE_TAG" ]; then
    echo "ERROR: Image tag is required."
    exit 1
fi

ECR_REGISTRY="207224908189.dkr.ecr.us-east-1.amazonaws.com"
ECR_REPOSITORY="flask-app"

NEW_IMAGE="$ECR_REGISTRY/$ECR_REPOSITORY:$NEW_IMAGE_TAG"

HAS_PREVIOUS=false
PREVIOUS_IMAGE=""

echo "========================================"
echo "Starting deployment"
echo "New image: $NEW_IMAGE"
echo "========================================"

# --------------------------------------------------
# 1. Detect currently deployed image
# --------------------------------------------------

if docker container inspect flask-app >/dev/null 2>&1; then
    PREVIOUS_IMAGE=$(docker inspect --format='{{.Config.Image}}' flask-app)
    HAS_PREVIOUS=true

    echo "Previous image: $PREVIOUS_IMAGE"
else
    echo "No existing flask-app container. First deployment."
fi

# --------------------------------------------------
# 2. Authenticate Docker with ECR
# --------------------------------------------------

echo "Logging in to ECR..."

aws ecr get-login-password \
    --region us-east-1 \
| docker login \
    --username AWS \
    --password-stdin "$ECR_REGISTRY"

# --------------------------------------------------
# 3. Pull new image BEFORE stopping old container
# --------------------------------------------------

echo "Pulling new image..."

docker pull "$NEW_IMAGE"

# --------------------------------------------------
# 4. Stop/remove current container
# --------------------------------------------------

if [ "$HAS_PREVIOUS" = true ]; then
    echo "Stopping current container..."
    docker stop flask-app

    echo "Removing current container..."
    docker rm flask-app
fi

# --------------------------------------------------
# 5. Start new container
# --------------------------------------------------

echo "Starting new container..."

if ! docker run -d \
    --name flask-app \
    -p 8000:8000 \
    --restart unless-stopped \
    "$NEW_IMAGE"
then
    echo "ERROR: Failed to start new container."

    if [ "$HAS_PREVIOUS" = false ]; then
        echo "No previous deployment exists."
        exit 1
    fi

    echo "Rolling back to: $PREVIOUS_IMAGE"

    docker rm flask-app 2>/dev/null || true

    docker run -d \
        --name flask-app \
        -p 8000:8000 \
        --restart unless-stopped \
        "$PREVIOUS_IMAGE"

    echo "Rollback container started."
    exit 1
fi

# --------------------------------------------------
# 6. Application health check
# --------------------------------------------------

HEALTHY=false

echo "Waiting for application health..."

for i in {1..10}; do

    if curl \
        --fail \
        --silent \
        --show-error \
        http://localhost:8000/health \
        >/dev/null 2>&1
    then
        echo "HEALTH CHECK PASSED"
        HEALTHY=true
        break
    else
        echo "Health check attempt $i failed"
        sleep 2
    fi

done

# --------------------------------------------------
# 7. Successful deployment
# --------------------------------------------------

if [ "$HEALTHY" = true ]; then
    echo "========================================"
    echo "Deployment successful."
    echo "Running image: $NEW_IMAGE"
    echo "========================================"

    exit 0
fi

# --------------------------------------------------
# 8. Health check failed → rollback
# --------------------------------------------------

echo "ERROR: New deployment failed health check."

if [ "$HAS_PREVIOUS" = false ]; then
    echo "No previous image exists."
    echo "Deployment failed with no rollback available."
    exit 1
fi

echo "Removing failed deployment..."

docker stop flask-app || true
docker rm flask-app || true

# --------------------------------------------------
# 9. Restore previous image
# --------------------------------------------------

echo "Rolling back to: $PREVIOUS_IMAGE"

docker run -d \
    --name flask-app \
    -p 8000:8000 \
    --restart unless-stopped \
    "$PREVIOUS_IMAGE"

# --------------------------------------------------
# 10. Verify rollback
# --------------------------------------------------

ROLLBACK_HEALTHY=false

echo "Checking rollback health..."

for i in {1..10}; do

    if curl \
        --fail \
        --silent \
        --show-error \
        http://localhost:8000/health \
        >/dev/null 2>&1
    then
        echo "ROLLBACK HEALTH CHECK PASSED"
        ROLLBACK_HEALTHY=true
        break
    else
        echo "Rollback health check attempt $i failed"
        sleep 2
    fi

done

# --------------------------------------------------
# 11. Final result
# --------------------------------------------------

if [ "$ROLLBACK_HEALTHY" = true ]; then
    echo "Rollback successful."
    echo "Previous version restored: $PREVIOUS_IMAGE"
else
    echo "CRITICAL: Rollback failed."
fi

exit 1
