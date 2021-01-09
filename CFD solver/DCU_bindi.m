% Donor Cell Upwinding Scheme
clear workspace;

% Define the bounds of the domain
ax = -1; ay = -1;
bx = 1; by = 1;

% grid spacing
dx = 1/64;
dy = 1/64;

% Step size
dt = 0.4*dx;   % DCU is unstable if ratio is greater than 0.25
T = ceil(pi/dt);

% Number of grid points is the same in x and y
N = (bx-ax)/dx;

% Define a grid with cell centers and edge centers
x = zeros(1,N); y = zeros(1,N);
for i = 1:1:(2*N+1)
    x(i) = ax + 0.5*(i-1)*dx;
    y(i) = ay +0.5*(i-1)*dy;
end

% Initial Conditions
q0 = zeros(N,N); 

for i = 1:1:N
    for j = 1:1:N
        if sqrt((x(2*i)+0.45)^2+y(2*j)^2) < 0.35
             q0(i,j) = 1-(sqrt((x(2*i)+0.45)^2+y(2*j)^2))/0.35;
        end
    end
end

for i = 1:1:N
    for j = 1:1:N
        if x(2*i) < 0.6 && x(2*i) > 0.1 && y(2*j) > -0.25  && y(2*j) < 0.25
             q0(i,j) = 1;
        end
    end
end

q = q0; 

% coordinates of cell centers
xp = zeros(1,N); yp = zeros(1,N);
for i = 1:1:N
    xp(i) = x(2*i);
    yp(i) = y(2*i);
end

% Define edge centered velocities u and v
uhalf = zeros(2*N+1, 2*N+1); vhalf = zeros(2*N+1,2*N+1);
uhalfp = zeros(2*N+1, 2*N+1); uhalfm = zeros(2*N+1, 2*N+1);
vhalfp = zeros(2*N+1, 2*N+1); vhalfm = zeros(2*N+1, 2*N+1);

 for i = 1:2:2*N+1
    for j = 2:2:2*N+1
        % Now take the velocity averages at each vertical edge
        %u(i-1/2,j)
        uhalf(i,j) = 2*y(j);
        uhalfp(i,j) = max(0,uhalf(i,j));
        uhalfm(i,j) = min(0,uhalf(i,j));
     end
end

   for j = 1:2:2*N+1   
       for i = 2:2:2*N+1
            % Now take the velocity averages at each horizontal edge
            %v(i,j-1/2)   
            vhalf(i,j) = -2*x(i);
            vhalfp(i,j) = max(0,vhalf(i,j));
            vhalfm(i,j) = min(0,vhalf(i,j));
       end
   end

qnew = zeros(N,N);
figure; 
% Create the video write with 1 fps
writerObj = VideoWriter('DCU.avi');
% Set the seconds per image
writerObj.FrameRate = 20;
% Open the video writer
open(writerObj);

for t = 1:1:T
    for i = 1:1:N
     for j = 1:1:N   
         if i == 1 || i == N || j == 1 || j == N
             % Use periodic boundary conditions
           qnew(i,j) = q(i,j) - (dt/dx)*(uhalfp(2*i-1,2*j)*(q(i,j)-q(N,j))+uhalfm(2*i+1,2*j)*(q(1,j)-q(i,j)))...
                  -(dt/dy)*(vhalfp(2*i,2*j-1)*(q(i,j)-q(i,N))+vhalfm(2*i,2*j+1)*(q(i,1)-q(i,j)));
         else
           qnew(i,j) = q(i,j) - (dt/dx)*(uhalfp(2*i-1,2*j)*(q(i,j)-q(i-1,j))+uhalfm(2*i+1,2*j)*(q(i+1,j)-q(i,j)))...
                  -(dt/dy)*(vhalfp(2*i,2*j-1)*(q(i,j)-q(i,j-1))+vhalfm(2*i,2*j+1)*(q(i,j+1)-q(i,j)));
         end
     end
    end
      q = qnew;
      surf(xp,yp,q,'LineStyle',':');
      xlabel('x');ylabel('y'); zlabel('q');
      colormap(jet(1000));
      colorbar;
      title(sprintf('DCU solution at (N=%d,time=%3.4f)', t,t*dt));
      %zlim([0 1]); 
      drawnow; 
      F(t) = getframe(gcf);
      frame = F(t);
      writeVideo(writerObj,frame);
      
      
end
 close (writerObj);
 
% Plot of 2D contour plot
figure;
% Define a vector to show certain, important contour lines only
v = [0.08 0.28 0.35 0.47 0.58 0.99 0.87 0.21 0.32 0.44 0.55 0.61 0.69];
contour(xp,yp,q,v);
xlabel('x'); ylabel('y');
axis equal;

% Plot of difference in analytical and DCU solution
figure;
g = q0-qnew;
surf(xp,yp,g);
colormap(jet(1000));
colorbar;
xlabel('x'); ylabel('y'); zlabel('q_{analytical}-q_{DCU}');
