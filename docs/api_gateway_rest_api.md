[AWS tutorial](https://docs.aws.amazon.com/lambda/latest/dg/services-apigateway-tutorial.html)

🌐 Task Flow — API Gateway (ClickOps)
🎯 Objective

Expose two Lambda functions through HTTP endpoints using API Gateway:

/python → Python Lambda

🧠 Concept Before Clicking

“Lambda does nothing until something calls it. API Gateway is how the outside world talks to your function.”

Mental model: Client → API Gateway → Lambda → Logs → Response

Key ideas:

  API Gateway = front door
  Lambda = execution engine
  Routes = decision logic

⚙️ Task 1 — Create API Gateway
📍 Navigation
AWS Console → API Gateway
Click: Create API

Choose👉 Rest API 

Click: Build (REST API)

🔗 Task 2 — Add Integrations

You’ll connect Lambda functions.

  ➤ Integration 1 (Python)
  Click Add integration
      Select: Lambda 
      Choose: chewbacca-python-lambda
      Sorry.... no Lizzo lambda... AWS Cloud isn't big enough for that.
  
  ➤ Integration 2 (Node.js)
  Click Add integration
  Select: Lambda
  Choose: chewbacca-node-lambda


🛣️ Task 3 — Configure Routes

Now define paths.

    ➤ Route 1 (Python)
    Method: GET
    Resource path: /python
    Integration: chewbacca-python-lambda

    ➤ Route 2 (Node)
    Method: GET
    Resource path: /node
    Integration: chewbacca-node-lambda

NOTE: “Routes are just pattern matching. API Gateway is deciding which Lambda to call.”

🚀 Task 4 — Deploy API
Click Next
Stage name: prod
Click Create

🌐 Task 5 — Get API Endpoint

You’ll see something like: https://abc123_yomomma_black.execute-api.us-east-1.amazonaws.com

This is your base URL.  Until you add WAF, Keisha and you momma will trouble you.

▶️ Task 6 — Test Endpoints

Python: curl "https://<api-id>.execute-api.<region>.amazonaws.com/python?name=Chewbacca"

Node: curl "https://<api-id>.execute-api.<region>.amazonaws.com/node?name=Malgus"

✅ Expected Results
Python

    {
      "message": "Hello Chewbacca from Python!",
      "timestamp": "..."
    }

Node

    {
      "message": "HELLO MALGUS FROM NODE!"
    }

🔍 Task 7 — Verify Logs (Critical)

Now we reinforce the operator mindset.

Student must:
1. Go to CloudWatch Logs
2. Check BOTH Lambdas:
    /aws/lambda/chewbacca-python-lambda
    /aws/lambda/chewbacca-node-lambda

3. Confirm:
  API Gateway triggered Lambda
  Event contains:
      query parameters
      headers
      request context

TEST: “What changed between test invocation and API invocation?”
1. What does API Gateway do?
2. What determines which Lambda is called?
3. What is the base URL vs route?
4. What happens if route is wrong?
5. What changed in the event?

End Note:

“API Gateway is not magic. It’s routing.”

“If you don’t understand the event payload, you don’t understand your system.”

“Logs tell you what actually happened, not what you think happened.”

🏁 Exit Criteria

Student passes this section when:

✔ API Gateway created
✔ Both routes working
✔ Curl/Postman requests succeed
✔ Logs confirm invocation
✔ Student explains request flow
✔ Student identifies event structure differences




# API GATEWAY
Client → Resource → Method → Integration → Lambda → Logs

What REST API Forces You To Understand

Unlike HTTP API, REST API makes you define:

    Resource → path (/python)
    Method → HTTP verb (GET)
    Integration → backend (Lambda)
    Deployment → publish changes

Task 1 — Create REST API

    📍 Navigation
    AWS Console → API Gateway
    Click Create API ---> REST API (NOT HTTP API)
    Endpoint Type: Regional
    Name: chewbacca-rest-api

Task 2 — Create Resources (Paths)

    Create /python
        Click Actions → Create Resource
        Resource Name: python
        Resource Path: /python
    Create /node
    Same process:
        Resource Name: node
        Path: /node

Task 3 — Create Methods

For /python
    Select /python
    Click Actions → Create Method
    Choose: GET

  Integration
    Integration type: Lambda Function
    Select: chewbacca-python-lambda
    Click Save

Repeat for /node
Connect to: chewbacca-node-lambda

Task 4 — Lambda Permissions

    “Add permission to Lambda?”
    Click: OK
    Remember: API Gateway must be allowed to invoke Lambda

Task 5 — Deploy API (MOST COMMON POINT of Frustration)

    “If you don’t deploy, your API does not exist.”
    Click: Actions → Deploy API
    Configure:
        Deployment stage: New Stage
        Stage name: prod

Task 6 — Get Invoke URL

    You’ll get: https://<api-id>.execute-api.<region>.amazonaws.com/prod

Task 7 — Test API

Chewbacca Python: curl "https://<api-id>.execute-api.<region>.amazonaws.com/prod/python?name=Chewbacca"
Chewbacca Node:  curl "https://<api-id>.execute-api.<region>.amazonaws.com/prod/node?name=Malgus"

Task 8 — Verify Logs
Go to CloudWatch
Find:
    /aws/lambda/chewbacca-python-lambda
    /aws/lambda/chewbacca-node-lambda


    # API Gateway Throttling
[Throttle requests with REST APIs](https://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-request-throttling.html)
[Terraform - Throttling](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_method_settings)

You can configure throttling and quotas for your APIs to help protect them from being overwhelmed by too many requests. Both throttles and quotas are applied on a best-effort basis and should be thought of as targets rather than guaranteed request ceilings.

API Gateway throttles requests to your API using the token bucket algorithm, where a token counts for a request. Specifically, API Gateway examines the rate and a burst of request submissions against all APIs in your account, per Region.
    * rate limit is the steady request rate allowed over time, measured in requests per second. How fast tokens refill each second.
    * burst limit is the short spike capacity above that steady rate, handled by a token bucket. How many tokens the bucket can hold at a time.

```
api_throttle_rate_limit  = 10
api_throttle_burst_limit = 20

Behavior:

A sudden spike can pass up to about 50 requests quickly (if bucket is full).
After that, traffic is governed by ~25 requests/second refill.
Extra requests beyond available tokens get throttled (429 Too Many Requests).


Test:
To test API Gateway throttling specifically, do one of these temporarily:

If WAF has been implemented do one of these temporarily:
    * Set WAF rate rule action to count (or increase WAF limit a lot), terraform apply, then retest.
    
    1. in .tfvars set the following:
    ```
    waf_rate_limit_action = "count"
    waf_rate_limit = 100
    ```

    2. then terraform apply

    * Temporarily set enable_waf = false, terraform apply, test for 429, then re-enable.

To test API Gateway throttling specifically, keep WAF in `count` mode so WAF does not block first.

API Gateway throttling test prerequisites:
- Both REST APIs must use `endpoint_configuration { types = ["REGIONAL"] }` in `api.tf`.
- Apply that change before testing. Stage throttling was not reliably observable while the APIs were using EDGE endpoints.

Recommended throttle validation flow:
1. Set `waf_rate_limit_action = "count"` in `terraform.tfvars`.
2. Temporarily lower the API Gateway throttle defaults in `variables.tf` to make validation obvious with a simple sequential loop:
    `api_throttle_rate_limit = 1`
    `api_throttle_burst_limit = 2`
3. Run `terraform apply`.
4. Test with:
    `url="$(terraform output -raw api_python_invoke_url)/PythonResource?name=throttle-test"`
    `for i in {1..20}; do curl -sS -o /dev/null -w "Request $i: %{http_code}\n" "$url"; done`

Expected result:
- Requests 1-2 usually return `200`.
- Most following requests return `429`.
- Occasional `200` responses can reappear as the token bucket refills.

Observed working example:
`Request 1: 200`
`Request 2: 200`
`Request 3: 429`
`Request 4: 429`
`Request 5: 429`
`Request 6: 200`

***VIP: How to switch back to blocking:***
After validation, restore production settings:
- In `variables.tf`, set `api_throttle_rate_limit = 25` and `api_throttle_burst_limit = 50`.
- In `terraform.tfvars`, set `waf_rate_limit_action = "block"`.
- Run `terraform apply` again.
