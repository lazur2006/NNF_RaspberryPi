from setuptools import setup

setup(
    name='NNF',
    version='0.0.1',    
    description='nicenfresh',
    url='https://github.com/lazur2006/NNF_releases/test',
    author='none',
    author_email='none@none.io',    
    license='MIT',
    packages=['NNF'],
    install_requires=['mpi4py>=2.0',
                      'numpy',
                      ],

    classifiers=[
        'Development Status :: 1 - Planning',
        'Intended Audience :: Science/Research',
        'License :: OSI Approved :: BSD License',  
        'Operating System :: POSIX :: Linux',        
        'Programming Language :: Python :: 2',
        'Programming Language :: Python :: 2.7',
        'Programming Language :: Python :: 3',
        'Programming Language :: Python :: 3.4',
        'Programming Language :: Python :: 3.5',
    ],
)    
