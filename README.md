# Trusty Music Fabricator (TMF)
Generate a Spotify playlist based on your current music interests by texting a Twilio-owned phone number.
Easy AWS-based serverless deployment that is completely pay-as-you-use (besides Spotify account and Twilio number, see their free trial).

## Setup Instructions
1. Create terraform.tfvars file with information needed in variables.tf - AWS account, spotify account, Twilio number, etc
2. Run setup.sh script to build app in AWS and update Twilio phone number webhook URL
3. Text your Trusty Music Fabricator to say hi, and enjoy :) 
4. Terraform destroy to get rid of everything in AWS if you want to 'uninstall', don't forget to release Twilio number!

## Current Version: 1.1.0
Deployment into AWS and automatic integration with Twilio webhook is working. Initial playlist is created with name "Trusty Music Fabricator" with correct number of songs, orders of magnitude faster than previous versions. Starting to introduce playlist customization through text body. 

## Usage Instructions
- In general, texting anything will refresh the TMF playlist
- Refreshing means - adding enough new songs to the playlist to reach the desired number, and replacing any 'neutral' songs that have been listened to a variable number of times (neutral_song_refresh_rate).
- Songs will be generated by randomly combining 1-3 songs in a user's Spotify current top tracks as seeds for a new song generation
- For more customizable playlist, several keywords can be included in the text body: "size #", "reset", and "keyword ~word~"

## Known Bugs / Issues / Needs
- [RESOLVED] Eliminate network resources / CFT and don't put TMF in a VPC! - Decreased cost and drastically improved speed with default Lambda Internet connectivity
- [RESOLVED] Spotify refresh token should be saved in SSM Parameter Store as encrypted string, not in S3 with songbank
- [RESOLVED] Network connectivity sometimes not working when app is invoked due to CloudFormation stack finishing NATGW->IGW resource and route creation immediately beforehand - added network connectivity test to check and wait a few seconds before trying again - VPCless architecture
- [RESOLVED] TMF doesn't immediately respond with warmup message - Hypothesis: API resource creation in TF is sometimes out of order enough to block Lambda response to text, APIGW returns 500 - updated to use trigger for APIGW TF instead of depends per AWS docs - haven't encountered error in 50+ deployments
- [RESOLVED] Songbank keeps track of / increments play count for songs even when removed from playlist
- [RESOLVED] TMF can fail when writing new songbank back to S3, put object call is timing out - network connectivity check at start and max retries/timeouts added for boto3, verified retries via CloudWatch logs
- [RESOLVED] Spotify calls can also timeout refreshing token - shorter timeout added, VPCless architecture
- [RESOLVED] TMF silently fails when texted during network stack deletion - no issue if warmup message works, no warmup message error in 50+ deployments
- [DEVELOPMENT] TMF ignores existing Spotify playlists with same name upon app setup, will create new playlist instead of choosing existing (should be variable option to overwrite)
- [RESOLVED] Update setup script to invoke Twilio API to update phone number instead of manually copy/pasting with MFA login
- [RESOLVED] Playlist doesn't have correct number of songs after songbank reset
- [DEVELOPMENT] Need ability to accidentally delete spotify playlist and resume without having to recreate songbank, overwrite keyword
- [RESOLVED] Need ability to temporarily remove cost-saving mode for faster responses for a user-texted amount of time - VPC-less architecture
- [BACKLOG] Use S3 bucket keys for KMS encryption to reduce cost 
- [DEVELOPMENT] Need ability to specify that all songs are replaced via Hello text - reset keyword - changed to 'keep' as reset is default starting in v1.1
- [RESOLVED] Happy/sad keywords to influence playlist tracks 
- [RESOLVED] Tempo keyword to influence playlist tracks
- [RESOLVED] Instrumental keyword for playlist, if present no vocals
- [RESOLVED] Energy keyword - energy high, medium, or low
- [TESTING] Dance keyword - want danceable tracks, needs tuning
- [DEVELOPMENT] Size keyword to temporarily change number of songs in playlist - smaller size no longer issue as all songs reset by default, can't use with 'keep' unless desired size is larger than current playlist size
- Want endless keyword so playlist keeps refreshing with new tracks as I listen without needing to text every so often, until I stop the endlessness via text
- Add S3 bucket versioning to be able to lookup previous songbanks if desired, lifecycle policy to avoid buildup
- [DEVELOPMENT] Seeds keyword along with track number in playlist to learn which songbank songs were used to generate the playlist song - need to keep track of 'parents' in songbank
- [DEVELOPMENT] Overall make songbank more readable with words instead of just spotify IDs?


- Multiplayer joint playlists??? - entirely new authentication setup required