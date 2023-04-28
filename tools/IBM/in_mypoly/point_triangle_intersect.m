function flag = point_triangle_intersect(Origin,Dir_ray,x_tri,y_tri,z_tri)

% size_x = size(x_tri);
% size_y = size(y_tri);
% size_z = size(z_tri);
% size_Dir_ray = size(Dir_ray);
% size_Origin = size(Origin);
% if(size_x(1)~=3 || size_x(2)~=1 || size_y(1)~=3 || size_y(2)~=1 || size_z(1)~=3 || size_z(2)~=1 || size_Dir_ray(1)~=3 || size_Dir_ray(2)~=1 || size_Origin(1)~=3 || size_Origin(2)~=1)
%     error('All inputs must be in 3x1 format.')
% end

% % triangle vertices
% x_tri = [5 5 5]';   
% y_tri = [0 5 5]';
% z_tri = [0 0 5]';
% 
% % Ray origin and direction
% Origin = [5 4.5 0]';
% Dir_ray = 5*[0 1 1]';

%%%%%%%%%%%%%

edge1 = [(x_tri(2)-x_tri(1)) (y_tri(2)-y_tri(1)) (z_tri(2)-z_tri(1))];
edge2 = [(x_tri(3)-x_tri(1)) (y_tri(3)-y_tri(1)) (z_tri(3)-z_tri(1))];

surf_norm = cross(edge1,edge2);

det1 = dot(cross(-Dir_ray,edge1),edge2);
rhs = Origin - [x_tri(1) y_tri(1) z_tri(1)]';
det_t =  dot(cross(rhs,edge1),edge2);
det_a =  dot(cross(-Dir_ray,rhs),edge2);
det_b =  dot(cross(-Dir_ray,edge1),rhs);
    
    if det1~= 0     %the ray intersects the plane of the triangle

        t = det_t/det1;
        a = det_a/det1;
        b = det_b/det1;
        if (a>=0 && b>=0 && a+b<=1 && t>=0)     %the ray intersects the plane within the domain bounded by the triangle (inclusive of edge and vertices)
            flag = true;
        else                                    %the ray DOES NOT intersect the plane within the domain bounded by the triangle
            flag = false;
        end

    elseif(det_a==0 && det_b==0 && det_t==0) % The ray is parallel to the plane of triangle and lie on the plane

        if (point_line_segment_intersect(Origin,Dir_ray,[x_tri(1) y_tri(1) z_tri(1)]',[x_tri(2) y_tri(2) z_tri(2)]')==true)
            flag = true;
        elseif (point_line_segment_intersect(Origin,Dir_ray,[x_tri(2) y_tri(2) z_tri(2)]',[x_tri(3) y_tri(3) z_tri(3)]')==true)
            flag = true;
        elseif (point_line_segment_intersect(Origin,Dir_ray,[x_tri(3) y_tri(3) z_tri(3)]',[x_tri(1) y_tri(1) z_tri(1)]')==true)
            flag = true;
        else                    % The ray DOES NOT intersect any of the triangle edges
            flag = false;
        end

    else                % The ray is parallel to the plane of triangle and DOES NOT intersect it

        flag = false;

    end
    
% figure
% hold on
% scatter3(x_tri,y_tri,z_tri)
% plot3(x_tri,y_tri,z_tri,'-o')
% quiver3(Origin(1),Origin(2),Origin(3),Dir_ray(1),Dir_ray(2),Dir_ray(3))