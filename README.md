#### gcp-sql-auto-authorize-instance

##### What is this?

This script is used to automatically authorize a GCP Auto-Scale Instance Group to a Google Cloud SQL database. The script does not rely on `gcloud`, allowing it be be associated with Google's Container-Optimized OS. This solution was inspired by [this serverfault post](https://serverfault.com/questions/778842/google-cloud-sql-authorize-auto-scale-instance-groups).

##### Why this solution?

Using the Cloud SQL Proxy seems to be the way GCP is pushing everyone to overcome this hurdle. However, keep in mind that once you go down that path, you'll be coupled to GCP. Your application will have to have direct knowledge of a GCP-specific component to be able to communicate with the DB -- something that is only necessary for the application to run in GCP, and nowhere else.

Due to this undesirable consequence, I have implemented this script. The advantage of this approach is that it isolates the logic necessary to communicate with the SQL instance, and associates it with GCP-specific configurations instead of the application itself.

The script code is the startup script I wrote to allow an auto-scaling instance group to gain authorization to a SQL instance. It runs inside GCP's Container-Optimized OS, which does not have gcloud installed.

##### How does it work?

1. Gain access to call the SQL API.
2. Get the IPs already authorized to the SQL database.
3. If the `$EXTERNAL_IP` of the new instance already exists in the authorized IPs, then return.
4. Otherwise, append the `$EXTERNAL_IP` to the authorized IPs, and `patch` the SQL database settings.