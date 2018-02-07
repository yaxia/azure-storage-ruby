require 'json'
require "base64"

require 'azure/storage/blob'
require 'azure/storage/common'
require "azure/core/http/debug_filter"

account_name = 'mytestaccount'
container_name = 'mytestcontainer'
block_blob_name = 'mytestblockblob'

def get_refresh_time_from_access_token(token)
  plain = Base64.decode64(token.split('.')[1])
  token_hash = JSON.parse plain
  expire_time_in_seconds = token_hash["exp"] - Time.now.to_i
  raise "The token has expired" if expire_time_in_seconds < 0

  # Max of 1 minute and 5 minutes before the token gets expired
  [60, expire_time_in_seconds - (5 * 60)].max
end

# Fetch your initial token here
initial_token = ""
next_refresh_time = get_refresh_time_from_access_token initial_token
cred = Azure::Storage::Common::Core::TokenCredential.new initial_token

cancelled = false
renew_token = Thread.new do
  Thread.stop
  while !cancelled
    sleep(next_refresh_time)
    puts "{DEBUG} Refresh token"
  
    # Renew token
    new_token = 'new_token'
    next_refresh_time = get_refresh_time_from_access_token new_token
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