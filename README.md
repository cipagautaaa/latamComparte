# LatamComparte Backend

## Descripción

LatamComparte es una aplicación backend desarrollada en Node.js que proporciona una API para gestionar noticias, países, solicitudes, testimonios y usuarios en la región de Latinoamérica. Este proyecto facilita el intercambio de información y recursos entre usuarios de diferentes países de la región.

## Características

- Gestión de usuarios con autenticación
- Publicación y gestión de noticias
- Información sobre países de Latinoamérica
- Sistema de solicitudes
- Testimonios de usuarios
- API RESTful

## Tecnologías Utilizadas

- Node.js
- Express.js
- MongoDB (asumiendo por los modelos)
- JWT para autenticación
- Otros middlewares y helpers según necesidad

## Instalación

1. Clona el repositorio:
   ```
   git clone <url-del-repositorio>
   cd latamComparte
   ```

2. Instala las dependencias:
   ```
   npm install
   ```

3. Configura las variables de entorno en un archivo `.env` (basado en el archivo existente).

4. Ejecuta el servidor:
   ```
   npm start
   ```

## Uso

La API estará disponible en `http://localhost:3000` (o el puerto configurado).

### Endpoints Principales

- `/auth`: Autenticación de usuarios
- `/noticias`: Gestión de noticias
- `/paises`: Información de países
- `/solicitudes`: Manejo de solicitudes
- `/testimonios`: Testimonios de usuarios

Consulta la documentación de la API para más detalles sobre los endpoints.

## Contribución

1. Crea una rama para tu feature: `git checkout -b feature/nueva-funcionalidad`
2. Realiza tus cambios y commits
3. Push a la rama: `git push origin feature/nueva-funcionalidad`
4. Crea un Pull Request

## Licencia

Este proyecto está bajo la Licencia MIT.

## Contacto

Para preguntas o soporte, contacta al equipo de desarrollo.
