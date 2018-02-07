require 'azure/storage/blob'
require 'azure/storage/common'
require "azure/core/http/debug_filter"

account_name = 'mytestaccount'
container_name = 'mytestcontainer'
block_blob_name = 'mytestblockblob'

# Fetch your initial token here
token = ""
cred = Azure::Storage::Common::Core::TokenCredential.new token

refresh_interval = 5
cancelled = false
renew_token = Thread.new do
  Thread.stop
  while !cancelled
    sleep(refresh_interval)
    puts "{DEBUG} Refresh token"
  
    # Renew token
    new_token = 'new_token'
    cred.renew_token new_token
  end
end
sleep 0.1 while renew_token.status != 'sleep'
renew_token.run

token_signer = Azure::Storage::Common::Core::Auth::TokenSigner.new cred
blob_token_client = Azure::Storage::Blob::BlobService.new(storage_account_name: account_name, signer: token_signer)
blob_token_client.with_filter Azure::Core::Http::DebugFilter.new

while renew_token.status != 'false'
  sleep(2)
  begin
    blob_properties = blob_token_client.get_blob_properties container_name, block_blob_name
  rescue Exception => e
    puts "{DEBUG} ex: #{e}"
  end
end

puts "{DEBUG} Process ends"