export default {
  async fetch(request: Request): Promise<Response> {
    const url = new URL(request.url);
    if (url.pathname === '/api/health') {
      return Response.json({ status: 'ok' });
    }
    return Response.json({ error: 'not_found' }, { status: 404 });
  },
} satisfies ExportedHandler<Env>;
