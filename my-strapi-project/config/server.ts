export default ({ env }) => ({
  host: env('HOST', '0.0.0.0'),
  port: env.int('PORT', 1337),
  app: {
    keys: env.array('APP_KEYS', [
      'your-secure-key-1',
      'your-secure-key-2',
      'your-secure-key-3',
      'your-secure-key-4',
    ]),
  },
  // add other server config properties here if needed
});

