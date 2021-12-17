
# OCI Private API Key

1. Sign in  
    > https://www.oracle.com/kr/cloud/sign-in.html

2. Download file  
    > Profile > User Settings > API Keys > Add API key > Download Private Key

3. Save to file `~/.oci/test.pem`
    > &nbsp;- *tenancy name `test`*

4. Click `Add` button in `Add API Key` popup window

5. Add `Configuration File Preview` to `~/.oci/config` file  
    > *Example*  
    &nbsp;- *oci config profile `[test]`*
    ```
    [test]
    user=ocid1.user.oc1..<unique_ID>
    tenancy=ocid1.tenancy.oc1..<unique_ID>
    fingerprint=<your_fingerprint>
    region=ap-xxx-1
    key_file=~/.oci/test.pem
    ```

----------

# oci-get-wavve-ip.sh

0. Prerequisite  
    > [OCI Private API Key](https://github.com/ssokka/ubuntu/tree/master/.oci#oci-private-api-key)

1. Edit `~/.oci/config`  
    ! Don't change `/root/.oci/` in `key_file`
    > *Example*  
    &nbsp;- *oci config profile `[test]`*  
    ```
    [test]
    user=ocid1.user.oc1..<unique_ID>
    tenancy=ocid1.tenancy.oc1..<unique_ID>
    fingerprint=<your_fingerprint>
    region=ap-xxx-1
    key_file=/root/.oci/test.pem
    ```

2. Download  
    ```
    mkdir -p "$HOME/.oci"
    cd "$HOME/.oci"
    curl -LO https://raw.githubusercontent.com/ssokka/ubuntu/master/.oci/oci-get-wavve-ip.sh
    ```

3. Run  
    ```
    bash oci-get-wavve-ip.sh [oci_config_profile] [discord_webhook_url]
    ```
    > *Example 1*  
    &nbsp;- *oci config profile `[DEFAULT]`*  
    &nbsp;- *no send discord message*
    ```
    bash oci-get-wavve-ip.sh
    ```
    > *Example 2*  
    &nbsp;- *oci config profile `[test]`*  
    &nbsp;- *no send discord message*
    ```
    bash oci-get-wavve-ip.sh test
    ```
    > *Example 3*  
    &nbsp;- *oci config profile `[test]`*  
    &nbsp;- *send discord message*
    ```
    bash oci-get-wavve-ip.sh test https://discord.com/api/webhooks/...
    ```

* *Receved discord message - Example*
    
    ![Succeed](https://media.discordapp.net/attachments/920134378686914570/920436851356094594/ZnqCpiwAAAABJRU5ErkJggg.png?width=263&height=171)
    ![Error](https://media.discordapp.net/attachments/920134378686914570/920435719573475380/mklMoVmKQdZ1kkIAEBIVyBggIUFhRCrMDA3zt2LcnXMMDAAAAAElFTkSuQmCC.png?width=243&height=171)

* *Multiple run of oci prifile*  
    > *Example*  
    &nbsp;- *oci config profile `[test2]`*  
    &nbsp;- *send discord message*
    ```
    bash oci-get-wavve-ip.sh test2 https://discord.com/api/webhooks/...
    ```