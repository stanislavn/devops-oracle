import unittest
import os
from django.test import Client


class HelloWorldTestCase(unittest.TestCase):
    def setUp(self):
        os.environ["DJANGO_SETTINGS_MODULE"] = "project.project.settings"
        self.client = Client()

    def test_hello_world(self):
        response = self.client.get("/")
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json(), {"message": "Hello, World!"})


if __name__ == "__main__":
    unittest.main()
