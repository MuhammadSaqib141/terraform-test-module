<policies>
    <inbound>
        <base />

        <!-- 🧩 JWT Validation -->
        <validate-jwt header-name="Authorization" failed-validation-httpcode="401" failed-validation-error-message="Unauthorized. Invalid or missing JWT.">
            <openid-config url="https://login.microsoftonline.com/81061c75-300e-4d0a-a517-23ed865d3866/v2.0/.well-known/openid-configuration" />
            
            %{ if jwt_audiences != null && length(jwt_audiences) > 0 ~}
            <audiences>
                %{ for aud in jwt_audiences ~}
                <audience>${aud}</audience>
                %{ endfor ~}
            </audiences>
            %{ endif ~}

            %{ if jwt_issuers != null && length(jwt_issuers) > 0 ~}
            <issuers>
                %{ for iss in jwt_issuers ~}
                <issuer>${iss}</issuer>
                %{ endfor ~}
            </issuers>
            %{ endif ~}
        </validate-jwt>

        <!-- 🌐 CORS Configuration -->
        <cors allow-credentials="${cors_allow_credentials}">
            <allowed-origins>
                %{ for origin in cors_allowed_origins ~}
                <origin>${origin}</origin>
                %{ endfor ~}
            </allowed-origins>
            <allowed-methods preflight-result-max-age="${cors_preflight_max_age}">
                %{ for method in cors_allowed_methods ~}
                <method>${method}</method>
                %{ endfor ~}
            </allowed-methods>
            <allowed-headers>
                %{ for header in cors_allowed_headers ~}
                <header>${header}</header>
                %{ endfor ~}
            </allowed-headers>
            <expose-headers>
                %{ for header in cors_expose_headers ~}
                <header>${header}</header>
                %{ endfor ~}
            </expose-headers>
        </cors>

        <!-- ⏱ Rate Limiting -->
        <rate-limit calls="${rate_limit_calls}" renewal-period="${rate_limit_period}" />

        <!-- 🚨 Simulated 500 error when forceError=true -->
        <choose>
            <when condition="@(context.Request.Url.Query.GetValueOrDefault("forceError", "") == "true")">
                <return-response>
                    <set-status code="500" reason="Simulated Internal Server Error" />
                    <set-header name="Content-Type" exists-action="override">
                        <value>application/json</value>
                    </set-header>
                    <set-body>@{
                        return new JObject(
                            new JProperty("error", "This is a simulated 500 Internal Server Error for testing alerting and monitoring.")
                        ).ToString();
                    }</set-body>
                </return-response>
            </when>
            <otherwise>

                <!-- 🔄 Normal Search Operation -->
                <set-backend-service base-url="${search_service_endpoint}" />
                <rewrite-uri template="/indexes/${search_index_name}/docs/search?api-version=${search_api_version}" />

                <set-body>@{
                    string query = context.Request.Url.Query.GetValueOrDefault("q", "*");
                    return new JObject(new JProperty("search", query)).ToString();
                }</set-body>

                <set-method>POST</set-method>

                <set-header name="api-key" exists-action="override">
                    <value>{{${ai_search_named_value}}}</value>
                </set-header>
                <set-header name="Content-Type" exists-action="override">
                    <value>application/json</value>
                </set-header>

            </otherwise>
        </choose>
    </inbound>

    <backend>
        <base />
    </backend>

    <outbound>
        <base />
    </outbound>

    <on-error>
        <base />
    </on-error>
</policies>
