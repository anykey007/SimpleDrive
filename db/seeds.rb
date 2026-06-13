def create_user(tenant, email, token)
  user = User.find_or_create_by!(tenant: tenant, email: email)
  ApiToken.find_or_create_by!(user: user, token_digest: Digest::SHA256.hexdigest(token))
end

# First tenant seeds
tenant = Tenant.find_or_create_by!(name: "Acme")

create_user(tenant, "john@acme.test", "e44319627c65ed15e80b36a9029a34c3eb3eb57cb2c13defa3fd8acf1b8ef7b9")

# Second tenant seeds
tenant = Tenant.find_or_create_by!(name: "Globex")

create_user(tenant, "jim@globex.test", "e572fbc29acf3a627f1dd8ac876de2a54d120febb2b7a3c4fd7cc1f6e49837f7")
create_user(tenant, "bob@globex.test", "303087315e1733f1336aa8ce0098d7852b7f880b2d1e8ae29961dead7ea1c07e")
