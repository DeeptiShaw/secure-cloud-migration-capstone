import sys, pathlib, unittest, os
sys.path.insert(0,str(pathlib.Path(__file__).resolve().parents[1]/'application/backend'))
from app import app
class ApiTests(unittest.TestCase):
    def setUp(self):
        os.environ['DEMO_TOKEN']='test-only'
        self.client=app.test_client()
    def test_health(self): self.assertEqual(self.client.get('/health').status_code,200)
    def test_denied(self): self.assertEqual(self.client.get('/api/orders').status_code,401)
    def test_invalid(self): self.assertEqual(self.client.post('/api/orders',json={'product_id':1,'quantity':0},headers={'Authorization':'Bearer test-only'}).status_code,400)
if __name__=='__main__': unittest.main()
