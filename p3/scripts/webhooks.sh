originalString=$(curl -s localhost:4040/api/tunnels | jq ".tunnels[0].public_url")
additionalString='/api/webhook'
modifiedString="${originalString%\"}$additionalString\""
curl --request POST \
  --url https://api.github.com/repos/AmineBarboura/abarbour/hooks \
  --header 'Accept: application/vnd.github+json' \
  --header 'Authorization: Bearer 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' \
  --header 'Content-Type: application/json' \
  --header 'X-GitHub-Api-Version: 2022-11-28' \
  --data '{
	"name":"web",
 "active":true,
 "events":["push"],
 "config": {
 "url": '$modifiedString',
	 "content_type":"json",
	 "insecure_ssl":"1"
 }
}'
