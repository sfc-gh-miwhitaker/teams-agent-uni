# Install Microsoft Teams App

**For:** End Users (with Teams access)  
**Time:** 5 minutes  
**Frequency:** Once per user

---

## Overview

This guide walks through installing the Snowflake Cortex Agents app in Microsoft Teams, connecting your Snowflake account, and starting to use the Joke Assistant agent.

---

## Prerequisites

- [ ] Microsoft Teams access (desktop, web, or mobile)
- [ ] Organizational Microsoft account (not personal)
- [ ] Entra ID tenant consent granted (done by admin)
- [ ] Snowflake account with Joke Assistant agent created
- [ ] Permission to install apps from AppSource

---

## Step 1: Install from Microsoft AppSource

### Option A: Via Microsoft Teams App Store

1. **Open Microsoft Teams**
   - Desktop app, web app, or mobile app

2. **Navigate to Apps**
   - Click **"Apps"** in the left sidebar
   - Or click the "..." menu and select **"Apps"**

3. **Search for Snowflake**
   - In the search bar, type: `Snowflake Cortex Agents`
   - Press Enter

4. **Install the App**
   - Click on **"Snowflake Cortex Agents"** card
   - Click **"Add"** or **"Get it now"**
   - If prompted for permissions, click **"Add"**

5. **Launch the App**
   - After installation, click **"Open"**
   - Or find it in your app list

### Option B: Via AppSource Website

1. **Navigate to AppSource**
   - Go to: https://appsource.microsoft.com/
   - Sign in with your organizational account

2. **Find the App**
   - Search: `Snowflake Cortex Agents`
   - Click on the app card

3. **Get the App**
   - Click **"Get it now"**
   - Select **"Add to Teams"**
   - Microsoft Teams will open automatically

4. **Complete Installation**
   - In Teams, click **"Add"**
   - Click **"Open"** to launch

---

## Step 2: Connect Your Snowflake Account

### 2.1: Initial Connection

When you first open the app, you'll see a welcome screen.

1. **Click "Connect Account"**
   - Or **"Add Snowflake Account"**

2. **Select Your Account Region**
   
   Choose your Snowflake account region from the dropdown:
   - AWS US East (N. Virginia)
   - AWS US West (Oregon)
   - Azure East US 2
   - Azure West Europe
   - GCP US Central1
   - (Or your specific region)

3. **Enter Account Identifier**
   
   Format options:
   - Account locator: `xy12345`
   - Full account name: `xy12345.us-east-1.aws`
   - Account URL: `https://xy12345.snowflakecomputing.com`

   **Find your account identifier:**
   ```sql
   -- In Snowflake, run:
   SELECT CURRENT_ACCOUNT();
   ```

### 2.2: Authenticate with Entra ID

1. **Click "Continue" or "Authenticate"**

2. **Sign in with Microsoft**
   - You'll be redirected to Microsoft login page
   - Use your organizational email and password
   - Complete any MFA challenges

3. **Grant Consent (if prompted)**
   
   If your account is NOT in Azure US East 2, you'll see:
   ```
   Data Processing Notice
   
   This integration processes (but does not store) data 
   in Snowflake's Azure East US 2 region.
   
   [ I Accept ] [ Cancel ]
   ```
   
   Click **"I Accept"** to proceed.

4. **OAuth Flow Completes**
   - You'll be redirected back to Teams
   - You should see: "Account connected successfully"

---

## Step 3: Select the Joke Assistant Agent

### 3.1: Choose Your Agent

1. After connecting, you'll see a list of available agents
2. Look for **"Joke Assistant"** or **"JOKE_ASSISTANT"**
3. Click on it to select

**Description you'll see:**
```
🎭 Joke Assistant

I'm your friendly AI assistant powered by Snowflake Cortex AI! 
Ask me for a joke about any topic, and I'll generate a clean, 
workplace-appropriate joke just for you.
```

### 3.2: Start Chatting

The chat interface will open. You'll see sample questions:
- "Tell me a joke about data engineers"
- "Give me a joke about SQL databases"
- "Make me laugh about cloud computing"

Click any sample question or type your own!

---

## Step 4: Test Your First Joke

### Try These Prompts:

**Example 1:**
```
Tell me a joke about data engineers
```

**Expected Response:**
```
🎭 Why do data engineers prefer dark mode? 
Because light attracts bugs, and they've already got 
enough of those in their pipelines! 😄

Want another one? Try asking about a different topic!
```

**Example 2:**
```
Give me a joke about SQL
```

**Expected Response:**
```
🎭 Why did the SQL query go to therapy? 
It had too many relationships but still felt empty! 🤣
```

**Example 3:**
```
Make me laugh about Snowflake
```

**Expected Response:**
```
🎭 Why did the data analyst fall in love with Snowflake? 
Because it scaled better than their coffee addiction! ☕❄️
```

---

## Using the Bot

### Basic Commands

**Request a joke:**
- "Tell me a joke about [topic]"
- "Give me a joke about [topic]"
- "Make me laugh about [topic]"
- "Something funny about [topic]"
- "Joke about [topic]"

**Topics to try:**
- Technology: Python, JavaScript, cloud computing, APIs
- Data: databases, SQL, data science, machine learning
- Work: meetings, deadlines, coffee, remote work
- General: any workplace-appropriate subject

### Advanced Usage

**Multiple jokes:**
```
Tell me a joke about data warehouses
[receives joke]
Now one about ETL pipelines
[receives another joke]
```

**Feedback (if available):**
- Some versions may have 👍/👎 buttons
- Use these to rate joke quality

---

## Managing Your Connection

### View Connected Accounts

1. Click the **"..."** menu in the bot
2. Select **"Settings"** or **"Manage Accounts"**
3. You'll see your connected Snowflake account(s)

### Switch Agents

1. In bot settings, click **"Select Agent"**
2. Choose a different agent from the list
3. Each agent has different capabilities

### Disconnect Account

1. Go to bot settings
2. Find your Snowflake account
3. Click **"Disconnect"** or **"Remove Account"**
4. Confirm disconnection

---

## Troubleshooting

### "Need admin approval" error

**Symptom:** Cannot connect, see admin approval message.

**Cause:** Tenant-wide consent not granted in Entra ID.

**Solution:**
- Contact your Azure administrator
- Share `config/entra_id_setup_guide.md` with them
- They need to grant tenant consent (5-minute task)

### "Account connection failed"

**Symptom:** Error during authentication.

**Causes & Solutions:**

1. **Wrong account identifier**
   ```sql
   -- Get correct identifier:
   SELECT CURRENT_ACCOUNT(), CURRENT_ACCOUNT_NAME();
   ```

2. **Wrong region selected**
   - Verify your account's region in Snowflake
   - Re-select correct region in Teams

3. **User mapping issue**
   - Your Microsoft email must match Snowflake user
   - Contact Snowflake admin to create matching user

### "No agents available"

**Symptom:** Agent list is empty after connecting.

**Causes & Solutions:**

1. **Agent not created**
   - Admin must complete `docs/04-CREATE-AGENT.md`

2. **No permissions**
   ```sql
   -- Admin must grant access:
   GRANT USAGE ON CORTEX AGENT SNOWFLAKE_EXAMPLE.CORTEX_DEMO.JOKE_ASSISTANT 
     TO ROLE PUBLIC;
   ```

3. **Wrong default role**
   ```sql
   -- Check your role:
   SELECT CURRENT_ROLE();
   
   -- Admin can change:
   ALTER USER your_username SET DEFAULT_ROLE = 'PUBLIC';
   ```

### Bot doesn't respond

**Symptom:** Message sent but no response.

**Solutions:**

1. **Wait longer** - First response can take 10-15 seconds
2. **Check Snowflake warehouse** - Must be running:
   ```sql
   SHOW WAREHOUSES LIKE 'SFE_CORTEX_AGENTS_WH';
   ALTER WAREHOUSE SFE_CORTEX_AGENTS_WH RESUME IF SUSPENDED;
   ```
3. **Simplify request** - Try: "Tell me a joke about data"

### "Sorry, I could not generate a safe joke..."

**Symptom:** Safety filter message instead of joke.

**Cause:** Topic triggered Cortex Guard safety filter.

**Solution:** Try a different, more neutral topic:
- ✅ Good: "data science", "databases", "cloud"
- ❌ Filtered: controversial, political, or sensitive topics

---

## Mobile App Usage

### iOS / Android

1. **Install Teams App**
   - Download from App Store or Google Play

2. **Find Snowflake App**
   - Tap **"Apps"** tab
   - Search **"Snowflake Cortex Agents"**
   - Tap **"Add"**

3. **Connect and Use**
   - Same process as desktop
   - OAuth may open in mobile browser
   - Return to Teams after authentication

---

## Microsoft 365 Copilot Integration

If your organization uses Microsoft 365 Copilot:

### Access Snowflake Agent in Copilot

1. **Open Microsoft 365 Copilot**
   - In Teams, Word, Outlook, or other M365 apps

2. **Mention Snowflake**
   - Type: `@Snowflake`
   - Or: "Ask Snowflake about..."

3. **Use Agent in Context**
   - Copilot will route queries to your Snowflake agent
   - Responses integrate into your conversation

**Example:**
```
In a Teams meeting chat:
"@Snowflake tell me a joke about data engineers to lighten the mood"
```

---

## Privacy & Security

### What Data is Shared?

**Shared with Snowflake:**
- Your prompts/questions
- Your Entra ID identity (email/UPN)
- OAuth tokens (short-lived)

**NOT shared:**
- Your Teams messages
- Other users' data
- Microsoft 365 files or emails

### What Can the Agent Access?

**Agent can only:**
- Execute queries as your Snowflake user
- Access data your role permits
- Call the joke generation function

**Agent cannot:**
- Access other users' data
- Bypass Snowflake RBAC
- Modify any data (read-only function)

### Audit Trail

All agent queries are logged:
```sql
-- Admin can audit usage:
SELECT USER_NAME,
       QUERY_TEXT,
       START_TIME,
       WAREHOUSE_NAME
FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
WHERE QUERY_TEXT LIKE '%GENERATE_SAFE_JOKE%'
ORDER BY START_TIME DESC;
```

---

## Next Steps

✅ **App installed**  
✅ **Account connected**  
✅ **Agent selected**  
✅ **First joke generated**

**Now explore:**

1. `docs/06-TESTING.md` - Fun testing scenarios
2. `docs/07-CUSTOMIZATION.md` - Extend for real use cases
3. Try different topics and share jokes with your team!

---

## Tips & Best Practices

### For Best Results

1. **Be specific** - "joke about ETL pipelines" vs. "joke about work"
2. **Keep it professional** - Stick to workplace-appropriate topics
3. **One topic at a time** - "joke about Python" (not "Python and Java and SQL")
4. **Try varied subjects** - Tech, data, industry-specific topics

### Share with Team

- Post funny results in Teams channels
- Use during virtual meetings to break the ice
- Create a "joke of the day" tradition

### Provide Feedback

- Use 👍/👎 if available
- Report any issues to your Snowflake admin
- Suggest new features or agent improvements

---

## Reference

- [Microsoft Teams App Management](https://support.microsoft.com/teams)
- [Snowflake Cortex Agents](https://docs.snowflake.com/user-guide/snowflake-cortex/cortex-agents-teams-integration)
- [Microsoft 365 Copilot](https://www.microsoft.com/microsoft-365/copilot)

