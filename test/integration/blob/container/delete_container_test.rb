#-------------------------------------------------------------------------
# # Copyright (c) Microsoft and contributors. All rights reserved.
#
# The MIT License(MIT)

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files(the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and / or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions :

# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#--------------------------------------------------------------------------
require "integration/test_helper"
require "azure/storage/blob/blob_service"

describe Azure::Storage::Blob::BlobService do
  subject { Azure::Storage::Blob::BlobService.new }
  after { ContainerNameHelper.clean }

  describe "#delete_container" do
    it "deletes the container" do
      container_name = ContainerNameHelper.name
      subject.create_container container_name
      result = subject.delete_container container_name
      result.must_be_nil
    end

    it "errors if the container does not exist" do
      assert_raises(Azure::Core::Http::HTTPError) do
        subject.delete_container ContainerNameHelper.name
      end
    end

    it "lease id works for delete_container" do
      container_name = ContainerNameHelper.name
      subject.create_container container_name
      lease_id = subject.acquire_container_lease container_name
      subject.release_container_lease container_name, lease_id
      new_lease_id = subject.acquire_container_lease container_name
      # assert wrong lease fails
      status_code = ""
      description = ""
      begin
        subject.delete_container container_name, lease_id: lease_id
      rescue Azure::Core::Http::HTTPError => e
        status_code = e.status_code.to_s
        description = e.description
      end
      status_code.must_equal "412"
      description.must_include "The lease ID specified did not match the lease ID for the container."
      # assert right lease succeeds
      subject.delete_container container_name, lease_id: new_lease_id
    end
  end
end
