<template>
  <v-app id="login" class="secondary">
    <v-content>
      <v-container fluid fill-height>
        <v-layout align-center justify-center>
          <v-flex xs12 sm8 md4 lg4>
            <v-card class="elevation-1 pa-3">
              <v-card-text>
                <div class="layout column align-center">
                  <img src="static/favicon.png" alt="Time Manager Login Portal" width="180" height="180">
                  <h1 class="flex my-4 primary--text">Time Manager</h1>
                </div>
                <v-form>
                  <v-text-field
                    append-icon="person"
                    name="login"
                    label="Login"
                    type="text"
                    v-model="email"
                    :error="error"
                    :rules="[rules.required]"/>
                  <v-text-field
                    :type="hidePassword ? 'password' : 'text'"
                    :append-icon="hidePassword ? 'visibility_off' : 'visibility'"
                    name="password"
                    label="Password"
                    id="password"
                    :rules="[rules.required]"
                    v-model="password"
                    :error="error"
                    @click:append="hidePassword = !hidePassword"/>
                </v-form>
              </v-card-text>
              <v-card-actions>
                <v-spacer></v-spacer>
                <v-btn block color="primary" @click="signUp" :loading="loading">Create new account</v-btn>
                <v-btn block color="primary" @click="login" :loading="loading">Login</v-btn>
              </v-card-actions>
            </v-card>
          </v-flex>
        </v-layout>
      </v-container>
      <v-snackbar
        v-model="showResult"
        :timeout="2000"
        top>
        {{ result }}
      </v-snackbar>
    </v-content>
  </v-app>
</template>

<script>
import axios from 'axios'

export default {
  data() {
    return {
      loading: false,
      email: '',
      password: '',
      hidePassword: true,
      error: false,
      showResult: false,
      result: '',
      rules: {
        required: value => !!value || 'Required.'
      }
    }
  },

  methods: {
    login() {
      const vm = this
      const data = {
        'email': vm.email,
        'password': vm.password
      }
      const headers = {
        'Content-Type': 'application/json'
      }
      if (!vm.email || !vm.password) {

        vm.result = "Email and Password can't be null.";
        vm.showResult = true;

        return
      }

      if (vm.email !== '' && vm.password !== '') {
        axios.post('/api/sign_in', data, {
          headers: headers
        })
          .then((res) => {
            if (res && res.data && res.data.status) {
              vm.$router.push({ name: 'Dashboard' })
            }
            else {
              vm.result = "Email or Password is incorrect."
            }
          })
      }
      else {
        vm.error = true;
        vm.result = "Email or Password is incorrect.";
        vm.showResult = true;
      }
    },
    trigger () {
    	this.$refs.sendReply.click()
    },
    signUp () {
      this.$router.push({path: '/signup'})
    }
  }
}
</script>

<style scoped lang="css">
  #login {
    height: 50%;
    width: 100%;
    position: absolute;
    top: 0;
    left: 0;
    content: "";
    z-index: 0;
  }
</style>
