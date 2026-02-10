# Conduit Manager StackScript

This project contains a Linode StackScript (`conduit-manager.sh`) to automate the deployment of Psiphon Conduit Manager on Ubuntu servers.

## Installation & Deployment

1.  Create a new StackScript in your Linode account with the content of `conduit-manager.sh`.
2.  Deploy a new Linode instance using this StackScript.
3.  Configure the User Defined Fields (UDFs) such as `MAX_CLIENTS`, `BANDWIDTH`, `CONTAINER_COUNT`, and Telegram settings during deployment.

### Important: Telegram Notifications

If you have enabled Telegram notifications in the configuration, please note that **you may need to manually restart the Telegram service after the server is built** for the bot to start working correctly with your configuration.

To do this, SSH into your server and run:

```bash
systemctl restart conduit-telegram
```

Or use the management menu to regenerate/restart the Telegram service.

## Conduit Manager Commands

Once installed, you can manage the conduit using the `conduit` command.

| Command | Description |
| :--- | :--- |
| `conduit` | Open the interactive management menu |
| `conduit status` | Quick status check with resource usage |
| `conduit stats` | View live statistics + CPU/RAM usage |
| `conduit logs` | View raw logs from the Docker container |
| `conduit peers` | Show live peer traffic by country |
| `conduit settings` | Change max-clients or bandwidth settings |
| `conduit scale` | Manage/Scale the number of running containers |
| `conduit backup` | Backup your node identity key |
| `conduit restore` | Restore a node identity key from backup |
| `conduit update` | Update the management script and Docker images |
| `conduit uninstall` | Completely remove Conduit and all components |
| `conduit version` | Show the current version |
| `conduit help` | Show help message |
| `conduit regen-tracker` | Regenerate/Restart the tracker service |
| `conduit regen-telegram` | Regenerate/Restart the Telegram notification service |

### Interactive Menu

Running `conduit` without arguments opens the interactive menu, which provides access to all features:

1.  **View status dashboard** — Real-time stats with peak, average, history.
2.  **Live connection stats** — Streaming stats from Docker logs.
3.  **View logs** — Raw Docker log output.
4.  **Live peers by country** — Per-country traffic table.
5.  **Start Conduit**
6.  **Stop Conduit**
7.  **Restart Conduit**
8.  **Update Conduit image**
9.  **Settings & Tools** — Resource limits, backups, Telegram, uninstall.
10. **Manage containers** — Add or remove containers.

For more details, visit the upstream repository: [https://github.com/SamNet-dev/conduit-manager](https://github.com/SamNet-dev/conduit-manager)
