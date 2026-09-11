from app import app

def test_home_route():
    client = app.test_client()
    response = client.get("/")
    assert response.data == b"Hello from Docker!"