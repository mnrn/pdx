#!/usr/bin/env fish

function fetch_pokemon
    mkdir -p data/pages

    set -l limit 100
    set -l offset 0

    while true
        set -l file (printf 'data/pages/%06d.json' $offset)

        if not test -s $file
            if not jq -n \
                --rawfile query graphql/pokeapi.gql \
                --argjson limit $limit \
                --argjson offset $offset \
                '{query: $query, variables: {limit: $limit, offset: $offset}}' |
                curl -fsS --max-time 60 \
                    'https://graphql.pokeapi.co/v1beta2' \
                    -H 'Content-Type: application/json' \
                    --data-binary @- |
                jq -e 'if .errors then error(.errors | tostring) else .data.pokemon end' > $file

                rm -f $file
                echo "Request failed at offset $offset" >&2
                return 1
            end
        end

        set -l count (jq 'length' $file)

        if test $count -eq 0
            rm -f $file
            break
        end

        echo "offset=$offset count=$count"
        set offset (math $offset + $count)
    end

    jq -s 'add' data/pages/*.json > data/pokemon-raw.json
    jq 'length' data/pokemon-raw.json
end

fetch_pokemon
