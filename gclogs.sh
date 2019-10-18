#!/bin/bash

SEARCH="$@"

gcloud logging read --format=json "resource.type=gae_app severity>=WARNING $SEARCH" |
    jq '[
          .[]
            | {
                startTime: .protoPayload.startTime,
                endTime: .protoPayload.endTime,
                method: .protoPayload.method,
                resource: .protoPayload.resource,
                status: .httpRequest.status,
                debug: [.protoPayload.line[] | select(.severity == "DEBUG") | .logMessage],
                error: [.protoPayload.line[] | select(.severity == "ERROR") | .logMessage],
                info: [.protoPayload.line[] | select(.severity == "INFO") | .logMessage],
                warning: [.protoPayload.line[] | select(.severity == "WARNING") | .logMessage]
              }
        ]
       '
