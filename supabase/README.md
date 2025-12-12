# Database Setup Instructions

## Step 1: Access Supabase

1. Go to [supabase.com](https://supabase.com)
2. Sign in to your account
3. Open your HireMeBuddy project

## Step 2: Run SQL Migrations

### Option A: Using SQL Editor (Recommended)

1. In Supabase Dashboard, click **SQL Editor** in the left sidebar
2. Click **New Query**
3. Copy and paste the contents of each file **in order**:

   **First:** `001_initial_schema.sql`
   - Creates all tables, enums, indexes, and triggers
   - Click **Run** button
   - Wait for "Success" message

   **Second:** `002_rls_policies.sql`
   - Creates all security policies
   - Click **Run** button
   - Wait for "Success" message

   **Third:** `003_seed_data.sql`
   - Adds initial service categories
   - Click **Run** button
   - Wait for "Success" message

### Option B: Using Supabase CLI (Advanced)

```bash
# Install Supabase CLI if not installed
npm install -g supabase

# Initialize Supabase in your project
supabase init

# Link to your remote project
supabase link --project-ref YOUR_PROJECT_REF

# Apply migrations
supabase db push
```

## Step 3: Enable Realtime (Optional but Recommended)

1. In Supabase Dashboard, go to **Database** > **Replication**
2. Enable realtime for these tables:
   - `bookings`
   - `messages`
   - `notifications`

## Step 4: Configure Storage

1. Go to **Storage** in Supabase Dashboard
2. Create the following buckets:

   **Bucket: profile-photos**
   - Public: Yes
   - File size limit: 5MB
   - Allowed MIME types: image/jpeg, image/png, image/webp

   **Bucket: provider-documents**
   - Public: No (private)
   - File size limit: 10MB
   - Allowed MIME types: image/jpeg, image/png, application/pdf

   **Bucket: portfolio-images**
   - Public: Yes
   - File size limit: 5MB
   - Allowed MIME types: image/jpeg, image/png, image/webp

3. Set up storage policies for each bucket (see storage_policies.sql if needed)

## Step 5: Verify Setup

1. Go to **Table Editor** in Supabase Dashboard
2. Verify all tables are created:
   - ✅ profiles
   - ✅ provider_profiles
   - ✅ service_categories
   - ✅ provider_services
   - ✅ bookings
   - ✅ reviews
   - ✅ messages
   - ✅ notifications
   - ✅ payments
   - ✅ admin_actions

3. Check **service_categories** table has 15 default categories

## Step 6: Create Test Admin User

1. Go to **Authentication** > **Users**
2. Click **Add user**
3. Create a test admin account:
   - Email: admin@hiremebuddy.com (or your email)
   - Password: (choose a secure password)
4. After creation, copy the user's UUID
5. Go to **SQL Editor** and run:
   ```sql
   UPDATE profiles 
   SET role = 'admin' 
   WHERE id = 'PASTE-USER-UUID-HERE';
   ```

## Step 7: Update Your App Config

Update `lib/core/config/supabase_config.dart` with your Supabase credentials if needed.

## Troubleshooting

### Error: "relation already exists"
- Some tables might already exist. Drop them first or skip that part of the script.

### Error: "permission denied"
- Make sure you're running the scripts with the service_role key (automatically used in SQL Editor).

### Error: "trigger already exists"
- The trigger `on_auth_user_created` might already exist. You can ignore this error.

## Next Steps

After database setup is complete:
1. ✅ Create Dart models matching the database schema
2. ✅ Set up Supabase service layer in the app
3. ✅ Implement authentication flow
4. ✅ Build client app features

---

**Database setup complete!** 🎉
You're now ready to start building the app features.
