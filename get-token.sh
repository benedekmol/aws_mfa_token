#!/bin/bash

#credential file
input="<CREDENTIAL FILE LOCATION>"

echo "Enter profile:"
read PROFILEE

echo "Enter MFA code:"
read MFA

CRED=$( aws sts get-session-token --serial-number <MFA device ARN> --token-code $MFA --output json | jq .Credentials )

#echo $CRED

ACCESSKEYID=$( echo $CRED | jq .AccessKeyId -r )
SECACCESSKEY=$( echo $CRED | jq .SecretAccessKey -r )
SESSIONTOKEN=$( echo $CRED | jq .SessionToken -r )


if [ "$SESSIONTOKEN" = "" ]; then
  echo "Session token query failed"
  exit 1
fi

#profile to modify
PROFILE="[$PROFILEE]"

#current config profile
KEY=""

touch /tmp/cred.tmp

cp "$input" "$input".bk

while IFS= read -r line
do 
  if echo "$line" | grep -q "\[.*\]"; then
    KEY="$line"
  fi  
  if [ "$KEY" = "$PROFILE" ] && echo "$line" | grep -q "^\s*aws_session_token"; then
    echo "aws_session_token = $SESSIONTOKEN" >> "/tmp/cred.tmp"
  elif [ "$KEY" = "$PROFILE" ] && echo "$line" | grep -q "^\s*aws_access_key_id"; then
    echo "aws_access_key_id = $ACCESSKEYID" >> "/tmp/cred.tmp"
  elif [ "$KEY" = "$PROFILE" ] && echo "$line" | grep -q "^\s*aws_secret_access_key"; then
    echo "aws_secret_access_key = $SECACCESSKEY" >> "/tmp/cred.tmp"
  else
    echo "$line" >> "/tmp/cred.tmp"
  fi
done < "$input"

if  ! [[ -f $input && -s $input ]]; then
  echo "Messed up somewhere backup available"
  rm /tmp/cred.tmp
  exit 1
fi

cp /tmp/cred.tmp "$input"
rm /tmp/cred.tmp

echo "🚀 SUCCESS"
