from downloadCustomers import main
import os

def test_document_download():
    file_name='JUNV19_OVR90120_Services.CSV'
    main.downloadFile(file_name)
    assert os.path.isfile('file.csv')

def test_csv_parsing():
    main.uploadCustomersToDynamoDB()
    assert True