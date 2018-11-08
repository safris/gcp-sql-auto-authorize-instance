### gcp-sql-auto-authorize-instance

#### What is this?

This script is used to automatically authorize a [GCP Auto-Scale Instance Group](https://cloud.google.com/compute/docs/autoscaler/) to a [Google Cloud SQL](https://cloud.google.com/sql/) database. The script does not rely on the `gcloud` command, allowing it be be associated with Google's Container-Optimized OS. This solution was inspired by [this ServerFault post](https://serverfault.com/questions/778842/google-cloud-sql-authorize-auto-scale-instance-groups).

#### Why this solution?

Using the [Cloud SQL Proxy](https://cloud.google.com/sql/docs/mysql/sql-proxy) seems to be the way GCP is pushing everyone to overcome this hurdle. However, keep in mind that once you go down that path, you'll be coupled to GCP. Your application will have to have direct knowledge of a GCP-specific component to be able to communicate with the DB -- something that is _only necessary_ for the application to run in GCP, and nowhere else.

Due to this undesirable consequence, I have implemented this script to avoid coupling your application to GCP. The advantage of this approach is that it isolates the logic necessary to communicate with the SQL instance, and associates it with GCP-specific configurations instead of the application itself.

[The script](/instance-group-startup.sh) will allow an auto-scaling instance group to automatically gain authorization to a SQL instance. It runs inside GCP's Container-Optimized OS, which does not have `gcloud` installed.

#### How to use it?

This script is meant to be used as the `Startup Script` in the configuration for a VM Instance Template.

To install this script:

1. In the script, replace `<your project id>` with your project id, and `<your db id>` with your DB id.
2. Go to [cloud.google.com](https://cloud.google.com/) -> Compute Engine -> Instance Templates.
3. Create a new Instance Template, or copy an existing one.
4. Click on `Management, security, disks, networking, sole tenancy` to expand the desired configuration fields.
5. In the `Automation` section, copy+paste the script you edited in (1) into the `Startup script` textbox.
6. Click `Create`, and you're done!

#### How does it work?

1. Gain access to call the SQL API.
2. Get the IPs already authorized to the SQL database.
3. If the `$EXTERNAL_IP` of the new instance already exists in the authorized IPs, then return.
4. Otherwise, append the `$EXTERNAL_IP` to the authorized IPs, and `patch` the SQL database settings.